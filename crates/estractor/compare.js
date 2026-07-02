import fs from "fs";

if (process.argv.length < 4) {
  console.error("Usage: node compare.js <file1.csv> <file2.csv>");
  process.exit(1);
}

const file1Path = process.argv[2];
const file2Path = process.argv[3];

function loadCSV(path) {
  const rows = fs.readFileSync(path, "utf8").trim().split("\n");
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

const file1 = loadCSV(file1Path);
const file2 = loadCSV(file2Path);

console.log("isin;name;ask_old;ask_new;diff_percent;flag");

for (const isin of Object.keys(file2)) {
  if (file1[isin] !== undefined) {
    const ask1 = file1[isin].ask;
    const ask2 = file2[isin].ask;
    const name = file2[isin].name || file1[isin].name;

    const diff = ((ask2 - ask1) / ask1) * 100;
	const flag = diff < 0 ? "-" : "+";

    console.log(`${isin};${name};${ask1};${ask2};${diff.toFixed(2)}%;${flag}`);
  }
}
