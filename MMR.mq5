//+------------------------------------------------------------------+
//|                                                          MMR.mq5 |
//|                                               Copyright 2024, TSA|
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, TSA"
#property link      "https://x.com/TS_algorithms"
#property link "https://t.me/TSalgorithms"
#property description "Market Manipulation Radar. Detects potential Market Manipulation and alerts the user via Telegram"
#property version   "1.00"
#property strict

#define MMR_YES    1
#define MMR_NO    0

input string symbolsToAnalyze = "XAUUSD,GBPUSD"; // Comma-separated list of symbols
input string botTkn = "";  // Telegram bot token
input string chatID = "";  // Chat ID for the Telegram chat
const string TG_API_URL = "https://api.telegram.org";  // Base URL for Telegram API
//+------------------------------------------------------------------+
//| Expert Trader class                                              |
//+------------------------------------------------------------------+
class CSymbolTrader
  {
private:
   string            symbol;               // Symbol to trade
   MqlTick           ExtLast_tick;         // Chart data
   MqlRates          ExtChartData[];       // Chart data for zigzag indicator
   int               ExtCopiedData;        // Data copied
   int               ExtCountLevels;       // Variable to count levels
   int               ExtZigzagHandle;      // Handle for Zigzag indicator
   int               ExtMMRFound;
   double            ExtLevelPrices[5];    // Level prices
   double            ExtZigzagData[];      // Zigzag data array
   datetime          ExtLevelTimes[5];     // Level times array
   datetime          ExtLastMMRTime;       // Variable to track time of MM detection
   ENUM_TIMEFRAMES   period;               // Timeframe for analysis

public:
   // Constructor that accepts the symbol as a parameter
                     CSymbolTrader(string pair)
     {
      symbol = pair;
      ExtCopiedData = 0;
      period = _Period; // Set default timeframe
      ExtMMRFound = 0;
      ExtLastMMRTime = 0;
     }

   // Method to identify support and resistance levels using ZigZag
   void              IdentifyLevels()
     {
      // Subtract 2 days in seconds from the current time
      datetime fromTime = TimeLocal() - 2 * 24 * 60 * 60;
      datetime toTime = TimeLocal(); // Current local time

      // Retrieve data for the specific symbol
      ExtCopiedData = CopyRates(symbol, period, fromTime, toTime, ExtChartData);
      if(ExtCopiedData <= 0)
        {
         // Print("Failed to retrieve data for symbol: ", symbol);
         return;
        }
      ArraySetAsSeries(ExtChartData, true);

      // Create ZigZag indicator handle for the specific symbol
      int zigzagDepth = 12;
      int zigzagDeviation = 7;
      int zigzagBackstep = 5;
      ExtZigzagHandle = iCustom(symbol, 0, "Examples/ZigZag", zigzagDepth, zigzagDeviation, zigzagBackstep);
      if(ExtZigzagHandle == INVALID_HANDLE)
        {
         //Print("Failed to apply ZigZag on symbol: ", symbol);
         return;
        }

      // Retrieve ZigZag data for the specific symbol
      int copiedZigzagData = CopyBuffer(ExtZigzagHandle, 0, 0, ExtCopiedData, ExtZigzagData);
      if(copiedZigzagData <= 0)
        {
         //Print("Failed to copy ZigZag buffer for symbol: ", symbol);
         return;
        }
      ArraySetAsSeries(ExtZigzagData, true);

      // Find most recent levels
      ExtCountLevels = 0;
      for(int i = 0; i < ExtCopiedData && ExtCountLevels <= 4; i++)
        {
         if(ExtZigzagData[i] > 0)
           {
            ExtLevelPrices[ExtCountLevels] = ExtZigzagData[i];
            ExtLevelTimes[ExtCountLevels] = ExtChartData[i].time;
            ExtCountLevels++;
           }
        }
     }

   // Method to identify potential market manipulation
   void              processTick()
     {
      if((TimeLocal() - ExtLastMMRTime) > 3600)
        {
         ExtMMRFound = MMR_NO;
         ExtLastMMRTime = 0;
        }

      // Get the current tick data
      if(!SymbolInfoTick(symbol, ExtLast_tick))
        {
         Print(symbol," = Error in SymbolInfoTick. Error code = ", GetLastError());
         return;
        }

      // Check if no signal has been created
      if(ExtMMRFound == 0)
        {
         // identify potential market manipulation and set ExtMMRFound flag accordingly
         if((ExtLevelPrices[1] > ExtLevelPrices[2]
             && ExtLevelPrices[1] >= ExtLevelPrices[3]
             && ExtLevelPrices[1] > ExtLevelPrices[4]
             && ExtLevelPrices[3] > ExtLevelPrices[4]
             && ExtLevelPrices[3] > ExtLevelPrices[2]
             && ExtLevelPrices[4] >= ExtLevelPrices[2]))
           {
            if(ExtLast_tick.ask <= ExtLevelPrices[2])
              {
               ExtLastMMRTime = TimeLocal();
               string message = StringFormat(
                                   "⚠️ Market Manipulation Alert!\nSymbol: %s\nTime: %s",
                                   symbol, TimeToString(ExtLastMMRTime));
               SendTelegramMessage(message);
               ExtMMRFound = MMR_YES;
              }
           }
         else
            if((ExtLevelPrices[2] > ExtLevelPrices[1]
                && ExtLevelPrices[2] >= ExtLevelPrices[4]
                && ExtLevelPrices[2] > ExtLevelPrices[3]
                && ExtLevelPrices[3] >= ExtLevelPrices[1]
                && ExtLevelPrices[4] > ExtLevelPrices[3]
                && ExtLevelPrices[4] > ExtLevelPrices[1]))
              {
               if(ExtLast_tick.bid >= ExtLevelPrices[2])
                 {
                  ExtLastMMRTime = TimeLocal();
                  string message = StringFormat(
                                      "⚠️ Market Manipulation Alert!\nSymbol: %s\nTime: %s",
                                      symbol, TimeToString(ExtLastMMRTime));
                  SendTelegramMessage(message);
                  ExtMMRFound = MMR_YES;
                 }
              }
        }
     }

   // Method for sending alerts to telegram
   void              SendTelegramMessage(string msg)
     {
      char data[];  // Array to hold data to be sent in the web request (empty)
      char res[];  // Array to hold the response data from the web request
      string resHeaders;  // String to hold the response headers from the web request

      // Construct the URL for the Telegram API request to send a message
      // Format: https://api.telegram.org/bot{HTTP_API_TOKEN}/sendmessage?chat_id={CHAT_ID}&text={MESSAGE_TEXT}
      const string url = TG_API_URL + "/bot" + botTkn + "/sendmessage?chat_id=" + chatID +
                         "&text=" + msg;

      // Check if the terminal is connected to the internet
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
        {
         Print("NETWORK IS NOT CONNECTED, UNABLE TO SEND MESSAGE.");
         return;
        }

      if(StringLen(botTkn) == 0 || StringLen(chatID) == 0)   // Validate inputs
        {
         Print("ERROR: Telegram bot token or chat ID is missing.");
         return;
        }

      // Send the web request to the Telegram API
      int send_res = WebRequest("POST", url, "", 10000, data, res, resHeaders);
      // Check the response status of the web request
      if(send_res == 200)
        {
         // If the response status is 200 (OK), print a success message
         Print("ALERT SENT TO TELEGRAM SUCCESSFULLY");
        }
      else
         if(send_res == -1)
           {
            // If the response status is -1 (error), check the specific error code
            if(GetLastError() == 4014)
              {
               // If the error code is 4014, it means the Telegram API URL is not allowed in the terminal
               Print("PLEASE ADD THE ", TG_API_URL, " TO THE TERMINAL");
               return;
              }
            // Print a general error message if the request fails
            Print("UNABLE TO SEND ALERT TO TELEGRAM");
            return;
           }
         else
            if(send_res != 200)
              {
               // If the response status is not 200 or -1, print the unexpected response code and error code
               Print("UNEXPECTED RESPONSE ", send_res, " ERR CODE = ", GetLastError());
               return;
              }
     }
  };
// Global variables for managing multiple symbols
CSymbolTrader *traders[]; // Array to hold symbol traders

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
   printf("\nINITIALIZING MMR\n");

// Split the input string by comma to get an array of symbols.
   string symbolsArray[];
   StringSplit(symbolsToAnalyze, ',', symbolsArray);

   int validSymbolCount = 0;  // Track the number of valid symbols.

// Loop through all symbols in the input array.
   for(int i = 0; i < ArraySize(symbolsArray); i++)
     {
      string symbol = symbolsArray[i];  // Get the current symbol.

      // Validate the symbol. If invalid, skip it.
      if(!ValidateSymbol(symbol))
        {
         Print("Skipping symbol: ", symbol);
         continue;  // Skip to the next symbol if validation fails.
        }

      // Resize the traders array dynamically as valid symbols are found.
      ArrayResize(traders, validSymbolCount + 1);

      // Create a CSymbolTrader instance for the valid symbol.
      traders[validSymbolCount] = new CSymbolTrader(symbol);

      // Identify levels for the valid symbol.
      traders[validSymbolCount].IdentifyLevels();

      // Increment the valid symbol count.
      validSymbolCount++;
     }
// Check if any valid symbols were found.
   if(validSymbolCount == 0)
     {
      Print("No valid symbols found. EA initialization aborted.");
      SendTelegramMessage("No valid symbols found. EA will stop.");
      ExpertRemove();  // Stop the EA if no valid symbols are found.
      return;
     }

   EventSetTimer(60);  // Set timer to call OnTimer every 1 minute.
   Print("MMR initialized successfully with ", validSymbolCount, " valid symbols.");
   SendTelegramMessage("MMR initialized successfully.");
  }

//+------------------------------------------------------------------+
//| Expert OnTimer function                                          |
//+------------------------------------------------------------------+
void OnTimer()
  {
// Identify levels and calculate Fibonacci for each symbol
   for(int i = 0; i < ArraySize(traders); i++)
     {
      traders[i].IdentifyLevels();
     }
  }

//+------------------------------------------------------------------+
//| Expert OnDeinit function                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i = 0; i < ArraySize(traders); i++)
     {
      if(traders[i] != NULL)   // Instead of nullptr
        {
         delete traders[i];
         traders[i] = NULL;  // Set to NULL after deletion
        }

     }
   EventKillTimer();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Call the OnTick method for each symbol trader
   for(int i = 0; i < ArraySize(traders); i++)
     {
      traders[i].processTick();
     }
  }
//+------------------------------------------------------------------+
//| Function for sending alerts to telegram                          |
//+------------------------------------------------------------------+
void              SendTelegramMessage(string msg)
  {
   char data[];  // Array to hold data to be sent in the web request (empty)
   char res[];  // Array to hold the response data from the web request
   string resHeaders;  // String to hold the response headers from the web request

// Construct the URL for the Telegram API request to send a message
// Format: https://api.telegram.org/bot{HTTP_API_TOKEN}/sendmessage?chat_id={CHAT_ID}&text={MESSAGE_TEXT}
   const string url = TG_API_URL + "/bot" + botTkn + "/sendmessage?chat_id=" + chatID +
                      "&text=" + msg;

// Check if the terminal is connected to the internet
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      Print("NETWORK IS NOT CONNECTED, UNABLE TO SEND MESSAGE.");
      return;
     }

   if(StringLen(botTkn) == 0 || StringLen(chatID) == 0)   // Validate inputs
     {
      Print("ERROR: Telegram bot token or chat ID is missing.");
      return;
     }

// Send the web request to the Telegram API
   int send_res = WebRequest("POST", url, "", 10000, data, res, resHeaders);
// Check the response status of the web request
   if(send_res == 200)
     {
      // If the response status is 200 (OK), print a success message
      Print("ALERT SENT TO TELEGRAM SUCCESSFULLY");
     }
   else
      if(send_res == -1)
        {
         // If the response status is -1 (error), check the specific error code
         if(GetLastError() == 4014)
           {
            // If the error code is 4014, it means the Telegram API URL is not allowed in the terminal
            Print("PLEASE ADD THE ", TG_API_URL, " TO THE TERMINAL");
            return;
           }
         // Print a general error message if the request fails
         Print("UNABLE TO SEND ALERT TO TELEGRAM");
         return;
        }
      else
         if(send_res != 200)
           {
            // If the response status is not 200 or -1, print the unexpected response code and error code
            Print("UNEXPECTED RESPONSE ", send_res, " ERR CODE = ", GetLastError());
            return;
           }
  }

//+------------------------------------------------------------------+
//| Function to validate symbol                                      |
//+------------------------------------------------------------------+
bool ValidateSymbol(string symbol)
  {
   if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
     {
      Print("ERROR: Symbol ", symbol, " is not available.");
      return false;
     }

   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
     {
      Print("ERROR: Trading is not allowed on ", symbol);
      return false;
     }

   return true;
  }
//+------------------------------------------------------------------+
