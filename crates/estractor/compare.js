import fs from "fs";
import path from "path";

function loadCSV(filePath) {
  const rows = fs.readFileSync(filePath, "utf8").trim().split("\n");
  rows.shift(); // remove header

  const map = {};
  for (const row of rows) {
    const [isin, name, ask] = row.split(";");
    map[isin] = {
      name,
      ask: parseFloat(ask)
    };
  }
  return map;
}

function compareFiles(file1Path, file2Path, createFallFile = false, writeAllFile = false) {
  const file1 = loadCSV(file1Path);
  const file2 = loadCSV(file2Path);

  console.log("isin;name;ask_old;ask_new;diff_percent;flag");

  const fallRows = [];
  const allRows = [];

  for (const isin of Object.keys(file2)) {
    if (file1[isin] !== undefined) {
      const ask1 = file1[isin].ask;
      const ask2 = file2[isin].ask;
      const name = file2[isin].name || file1[isin].name;

      const diff = ((ask2 - ask1) / ask1) * 100;
      const flag = diff < 0 ? "-" : "+";

      const row = `${isin};${name};${ask1};${ask2};${diff.toFixed(2)}%;${flag}`;
      console.log(row);

      allRows.push(row);
      if (flag === "-") fallRows.push(row);
    }
  }

  const now = new Date();
  const stamp = now.toISOString().replace(/[:.]/g, "-");

  if (createFallFile && fallRows.length > 0) {
    const outName = `fall-${stamp}.csv`;
    fs.writeFileSync(outName, "isin;name;ask_old;ask_new;diff_percent;flag\n" + fallRows.join("\n"));
    console.log(`\nCreated ${outName} with ${fallRows.length} falling rows.`);
  }

  if (writeAllFile && allRows.length > 0) {
    const outName = `diff-${stamp}.csv`;
    fs.writeFileSync(outName, "isin;name;ask_old;ask_new;diff_percent;flag\n" + allRows.join("\n"));
    console.log(`\nCreated ${outName} with ${allRows.length} rows.`);
  }
}

function compareLatests(dirPath, createFallFile = false, writeAllFile = false) {
  const files = fs.readdirSync(dirPath)
    .filter(f => f.endsWith(".csv"))
    .sort();

  if (files.length < 2) {
    console.error("Not enough CSV files in directory.");
    process.exit(1);
  }

  const latest = files[files.length - 1];
  const previous = files[files.length - 2];

  const file1Path = path.join(dirPath, previous);
  const file2Path = path.join(dirPath, latest);

  console.log(`Comparing latest files:\n  OLD: ${previous}\n  NEW: ${latest}\n`);
  compareFiles(file1Path, file2Path, createFallFile, writeAllFile);
}

// -------------------- MAIN --------------------

const args = process.argv.slice(2);

const createFallFile = args.includes("-fall");
const writeAllFile = args.includes("-w");

const cleanArgs = args.filter(a => a !== "-fall" && a !== "-w");

if (cleanArgs.length === 1) {
  compareLatests(cleanArgs[0], createFallFile, writeAllFile);

} else if (cleanArgs.length === 2) {
  compareFiles(cleanArgs[0], cleanArgs[1], createFallFile, writeAllFile);

} else {
  console.error("Usage:");
  console.error("  node compare.js <dir> [-fall] [-w]");
  console.error("  node compare.js <file1> <file2> [-fall] [-w]");
  process.exit(1);
}
