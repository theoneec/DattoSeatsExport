# DattoSeatsExport
# 🔐 Datto SaaS Protection Seat Export Script

This PowerShell script connects to the **Datto SaaS Protection API**, retrieves a list of protected domains, and queries each domain for **individual seat-level backup data**. It then exports all results to a CSV file for easy reporting or analysis.

---

## 📦 Features

- Authenticates using **Basic Auth** via public/secret keys passed at runtime
- Queries `/v1/saas/domains` for a list of SaaS-protected companies
- Queries `/v1/saas/{saasCustomerId}/seats` to fetch individual backup seat details
- Outputs results to `Datto_SaaS_Seats.csv` in the script directory
- Runs entirely non-interactively (no prompts)
- Suitable for automation or scheduled task usage

---

## 🚀 Usage

### Run the script with API keys as parameters

```powershell
.\DattoSeatsExport.ps1 -PublicKey "your_public_key" -SecretKey "your_secret_key"
