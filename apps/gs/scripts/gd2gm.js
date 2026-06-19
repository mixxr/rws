// Replace these with your own values
const PARENT_FOLDER_ID = "1234567890";
const DEFAULT_TO = "test@gmail.com";

// use the JSON example to understand how the email is composed

const main = () => {
  sendDailyJsonSummaries(PARENT_FOLDER_ID, DEFAULT_TO)
}

const sendDailyJsonSummaries = (parentFolderId,toEmail) => {
  // 1. Data odierna in formato YYYY-MM-DD
  const today = new Date();
  const todayDate  = today.toISOString().slice(0, 10); // YYYY-MM-DD

  // 2. retrieve files
  const parentFolder = DriveApp.getFolderById(parentFolderId);

  const allFiles = parentFolder.getFiles();
  const matchedFiles = [];

  while (allFiles.hasNext()) {
    const file = allFiles.next();
    const name = file.getName().toLowerCase();

    if (name.includes(todayDate.toLowerCase()) && name.endsWith(".json")) {
      matchedFiles.push(file);
    }
  }

  if (matchedFiles.length === 0) {
    Logger.log("Nessun file trovato con pattern *" + todayDate + "*.json");
    return;
  }

  // 3. Cerca il subfolder con nome = YYYY-MM-DD
  let subfolder;
  const subfolders = parentFolder.getFoldersByName(todayDate);

  if (subfolders.hasNext()) {
    subfolder = subfolders.next();
  } else {
    subfolder = parentFolder.createFolder(todayDate);
    Logger.log("Creato subfolder: " + todayDate);
  }

  // 4. Process files
  matchedFiles.forEach(file => {
     try {
        const content = file.getBlob().getDataAsString();

          const json = JSON.parse(content);
          const stocks = json.stocks || [];
          const tech = json.technical_analysis || {};
          const details = json.details || {};

          const title = json.article_title || "Article Title Not Provided";
          const summary = formatSummary(json.executive_summary, stocks);
          const summaryIt = formatSummary(json.executive_summary_it, stocks);

          const body = `
          <div style="font-family:Arial, sans-serif; font-size:14px;">

            <h2>Executive Summary</h2>
            <p>${summary}</p>

            <hr/>

            <h2>Executive Summary (Italiano)</h2>
            <p>${summaryIt}</p>

            <br><hr/>

            <h2>Technical Analysis</h2>
            ${buildTechnicalTable(tech)}
            <br/>

            <h2>Details</h2>
            ${buildDetailsTable(details)}
            <br/>

            <br/>
            <a href='${json.source}'>${title}</a>

          </div>
        `;
          // 5. Invia email
          MailApp.sendEmail({
            to: toEmail, //Session.getActiveUser().getEmail(),
            subject: title,
            htmlBody: body
          });

          Logger.log("Email inviata per file: " + file.getName());
          // Sposta il file nel subfolder YYYY-MM-DD
          file.moveTo(subfolder);
          Logger.log("File moved to: " + subfolder);

          // subfolder.addFile(file);
          // parentFolder.mo.removeFile(file);

        } catch (err) {
          Logger.log("Errore parsing JSON per file " + file.getName() + ": " + err);
        }
  });
}


const formatSummary = (text, stocks) => {
  if (!text) return "";

  let formatted = text;

  // --- 1. Aggiungi <br/><br/> dopo ogni punto fermo che chiude una frase ---
  formatted = formatted.replace(/\. +/g, ".<br/>");

  // --- 2. Evidenzia indicatori tecnici ---
  const indicators = ["MACD", "RSI", "Williams %R", "Williams%R", "Williams% R"];
  indicators.forEach(ind => {
    const regex = new RegExp(ind, "gi");
    formatted = formatted.replace(regex, `<b>${ind}</b>`);
  });

  // --- 3. Evidenzia gli stock presenti nel JSON ---
  if (Array.isArray(stocks)) {
    stocks.forEach(stock => {
      const symbol = stock.split(":")[1]; // es. NASDAQ:MU → MU
      const regex = new RegExp(symbol, "g");
      formatted = formatted.replace(regex, `<b>${symbol}</b>`);
    });
  }

  return formatted;
};

const buildTechnicalTable = (tech) => {
  if (!tech || typeof tech !== "object") return "<p>N/A</p>";

  let html = `
    <table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; font-size:13px;">
      <tr style="background:#f2f2f2;">
        <th>Indicator</th>
        <th>Value</th>
        <th>Recommendation</th>
      </tr>
  `;

  const indicators = ["macd", "rsi", "williamR"];

  indicators.forEach(ind => {
    if (tech[ind]) {
      html += `
        <tr>
          <td><b>${ind.toUpperCase()}</b></td>
          <td>${tech[ind].value || "N/A"}</td>
          <td>${tech[ind].recommendation || "N/A"}</td>
        </tr>
      `;
    }
  });

  html += "</table>";
  return html;
};

const buildDetailsTable = (details) => {
  if (!details || typeof details !== "object") return "<p>N/A</p>";

  let html = `
    <table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; font-size:13px; margin-top:10px;">
      <tr style="background:#e8e8e8;">
        <th>Metric</th>
        <th>Value</th>
      </tr>
  `;

  // --- PE (tabella interna per stock) ---
  if (details.pe) {
    let peHtml = "<table border='0' cellpadding='4' cellspacing='0' style='font-size:12px;'>";
    Object.keys(details.pe).forEach(symbol => {
      peHtml += `
        <tr>
          <td><b>${symbol}</b></td>
          <td>${details.pe[symbol]}</td>
        </tr>
      `;
    });
    peHtml += "</table>";

    html += `
      <tr>
        <td><b>P/E</b></td>
        <td>${peHtml}</td>
      </tr>
    `;
  }

  // --- Profit Growth ---
  if (details.profit_growth) {
    html += `
      <tr>
        <td><b>Profit & Revenue Growth</b></td>
        <td>
          ${details.profit_growth.value || "N/A"}<br/>
          <i>${details.profit_growth.period || ""}</i>
        </td>
      </tr>
    `;
  }

  // --- Media Coverage ---
  if (details.media_coverage) {
    html += `
      <tr>
        <td><b>Media Coverage</b></td>
        <td>${details.media_coverage}</td>
      </tr>
    `;
  }

  // --- Sentiment ---
  if (details.sentiment) {
    html += `
      <tr>
        <td><b>Sentiment</b></td>
        <td>${details.sentiment}</td>
      </tr>
    `;
  }

  // --- Volumes Attitude ---
  if (details.volumes_attitude) {
    html += `
      <tr>
        <td><b>Volumes Attitude</b></td>
        <td>${details.volumes_attitude}</td>
      </tr>
    `;
  }

  html += "</table>";
  return html;
};

