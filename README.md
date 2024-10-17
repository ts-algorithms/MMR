# **Market Manipulation Radar (MMR) EA**  

**Version:** 1.00  
**Author:** TSA (Trading Solutions and Algorithms)  
**Description:**  
The Market Manipulation Radar (MMR) is an automated Expert Advisor (EA) built for MetaTrader 5. It analyzes price movements using the **ZigZag indicator** to identify potential market manipulation. When a manipulation pattern is detected, it sends an alert to a specified **Telegram chat** via the Telegram Bot API.

## **Features**  
- **Symbol Analysis:** Monitors multiple symbols (e.g., XAUUSD, GBPUSD) to detect price manipulation patterns.
- **ZigZag Indicator:** Uses historical levels identified by the ZigZag indicator to detect support/resistance levels.
- **Telegram Notifications:** Sends alerts when suspicious price behavior is detected.
- **Multi-Currency Support:** Monitors several pairs simultaneously.
- **Real-Time Alerts:** Alerts are sent instantly via the Telegram Bot for prompt action.

## **Installation Guide**  
1. **Download the EA**  
   - Save the `MMR.mq5` file into the following directory in your MetaTrader 5 terminal:  
     ```
     <MT5_Directory>/MQL5/Experts/
     ```
  
2. **Compile the EA**  
   - Open the `MMR.mq5` file in the **MetaEditor** and click **Compile** to ensure there are no errors.

3. **Enable Web Requests**  
   - Open MetaTrader 5.
   - Go to **Tools** > **Options** > **Expert Advisors**.
   - Under **Allow WebRequest for listed URLs**, add the following URL:
     ```
     https://api.telegram.org
     ```
  
4. **Set Telegram Bot Token and Chat ID**  
   - Create a Telegram bot by messaging **@BotFather** on Telegram and note the token provided.
   - Add your **chat ID** (obtainable via a bot like **@userinfobot**).
   - Update the `botTkn` and `chatID` inputs in the EA with your token and chat ID.

## **How to Use**  
1. **Attach the EA to a Chart:**  
   - Open the MetaTrader 5 terminal.
   - Select any chart (e.g., XAUUSD).
   - Drag the MMR EA onto the chart and ensure **AutoTrading** is enabled.

2. **Inputs Configuration:**  
   - `symbolsToAnalyze`: Comma-separated list of symbols to monitor (e.g., `XAUUSD,GBPUSD`).
   - `botTkn`: Your Telegram bot token (from **BotFather**).
   - `chatID`: Telegram chat ID to receive alerts.

3. **Monitoring and Alerts:**  
   - The EA runs continuously, analyzing the configured symbols for suspicious price behavior.
   - If manipulation is detected, it sends a **Telegram alert** with the symbol and detection time.

## **Code Structure**  
- **`CSymbolTrader` Class**  
  - Manages individual symbols, identifies support/resistance levels using the ZigZag indicator, and detects manipulation patterns.
- **`SendTelegramMessage()` Method**  
  - Sends alerts via the Telegram Bot API.
- **`OnInit()`**  
  - Initializes the EA and sets up symbol monitoring.
- **`OnTick()`**  
  - Processes incoming ticks and checks for manipulation patterns.
- **`OnTimer()`**  
  - Updates the levels every minute to keep the analysis fresh.

## **Telegram Alerts Example**  
If the EA detects potential market manipulation, you’ll receive a message like:  
⚠️ Market Manipulation Alert! Symbol: XAUUSD Time: 2024.10.17 01:00

markdown
Copy code

## **Dependencies**  
- MetaTrader 5 platform  
- ZigZag indicator (built-in)  
- Telegram Bot API  

## **Troubleshooting**  
1. **EA not sending alerts:**  
   - Ensure **AutoTrading** is enabled.
   - Confirm that the Telegram API URL is allowed in **WebRequest** settings.
   - Verify the bot token and chat ID are correct.

2. **Unexpected Errors:**  
   - Check the **Experts** tab for any error messages.
   - If you receive the error **4014**, add `https://api.telegram.org` to WebRequest permissions.

## **Disclaimer**  
This EA is intended for educational purposes. Use it at your own risk. The developer is not responsible for any financial losses incurred while using this software.

## **Contact**  
For questions or support, reach out on:
X/Twitter: [@TS_algorithms](https://https://x.com/TS_algorithms)  
Telegram: [@TSalgorithms](https://t.me/TSalgorithms)

