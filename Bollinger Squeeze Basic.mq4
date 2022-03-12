//+--------------------------------------------------------------------------+
//|                                              Bollinger Squeeze Basic.mq4 |
//|                                          Copyright © 2022, EarnForex.com |
//| https://www.earnforex.com/metatrader-indicators/Bollinger-Squeeze-Basic/ |
//+--------------------------------------------------------------------------+
#property copyright "Copyright © 2022, EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Bollinger-Squeeze-Basic/"
#property version   "1.00"
#property strict

#property description "Bollinger Squeeze Basic shows the change of momentum histogram and BB / Keltner channel dots."
#property description "Red dots are shown when Bollinger bands are outside of the Keltner channel."
#property description "Blue dots are shown when Bollinger bands are inside the Keltner channel."

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1 clrLimeGreen
#property indicator_type1  DRAW_HISTOGRAM
#property indicator_width1 2
#property indicator_color2 clrIndianRed
#property indicator_width1 2
#property indicator_label1 "Momentum Histo"
#property indicator_type2  DRAW_HISTOGRAM
#property indicator_width2 2
#property indicator_label2 "Momentum Histo"
#property indicator_color3 clrLightGreen
#property indicator_type3  DRAW_HISTOGRAM
#property indicator_width3 2
#property indicator_label3 "Momentum Histo"
#property indicator_color4 clrLightPink
#property indicator_type4  DRAW_HISTOGRAM
#property indicator_width4 2
#property indicator_label4 "Momentum Histo"
#property indicator_color5 clrBlue
#property indicator_type5  DRAW_ARROW
#property indicator_label5 "BB/Keltner"
#property indicator_color6 clrRed
#property indicator_type6  DRAW_ARROW
#property indicator_label6 "BB/Keltner"

enum enum_candle_to_check
{
    Current,
    Previous
};

input int    MaxBars = 300;
input int    BB_Period = 20; // BB Period
input double BB_Deviation = 2.0; // BB Deviation
input int    Keltner_Period = 20; // Keltner Period
input double Keltner_Factor = 1.5; // Keltner Factor
input int    Momentum_Period = 12; // Momentum Period
input bool   EnableNativeAlerts = false;
input bool   EnableEmailAlerts = false;
input bool   EnablePushAlerts = false;
input enum_candle_to_check TriggerCandle = Previous;

// Indicator buffers:
double upB[];
double loB[];
double upK[];
double loK[];
double upB2[];
double loB2[];

// Global variables:
datetime LastAlertTime = D'01.01.1970';
int LastAlertDirection = 0;

void OnInit()
{
    SetIndexBuffer(0, upB);
    SetIndexEmptyValue(0, 0);

    SetIndexBuffer(1, loB);
    SetIndexEmptyValue(1, 0);

    SetIndexBuffer(2, upB2);
    SetIndexEmptyValue(2, 0);

    SetIndexBuffer(3, loB2);
    SetIndexEmptyValue(3, 0);

    SetIndexBuffer(4, upK);
    SetIndexEmptyValue(42, EMPTY_VALUE);
    SetIndexArrow(4, 167);

    SetIndexBuffer(5, loK);
    SetIndexEmptyValue(5, EMPTY_VALUE);
    SetIndexArrow(5, 167);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int limit = MaxBars;
    if (limit > Bars) limit = Bars;

    double d = 0, prev_d = 0;
    
    for (int shift = limit - 1; shift >= 0; shift--)
    {
        d = iMomentum(NULL, 0, Momentum_Period, PRICE_CLOSE, shift) - 100;

        if (d > 0)
        {
            if (d >= prev_d)
            {
                upB[shift] = d;
                upB2[shift] = 0;
            }
            else
            {
                upB2[shift] = d;
                upB[shift] = 0;
            }

            loB[shift] = 0;
            loB2[shift] = 0;
        }
        else if (d < 0)
        {

            if (d <= prev_d)
            {
                loB[shift] = d;
                loB2[shift] = 0;
            }
            else
            {
                loB2[shift] = d;
                loB[shift] = 0;
            }
            upB[shift] = 0;
            upB2[shift] = 0;
        }
        else
        {
            upB[shift] = 0.01;
            upB2[shift] = 0.01;
            loB[shift] = -0.01;
            loB2[shift] = -0.01;
        }
        prev_d = d;

        double diff = iATR(NULL, 0, Keltner_Period, shift) * Keltner_Factor;
        double std = iStdDev(NULL, 0, BB_Period, MODE_SMA, 0, PRICE_CLOSE, shift);
        double bbs = BB_Deviation * std / diff;

        if (bbs < 1)
        {
            upK[shift] = 0;
            loK[shift] = EMPTY_VALUE; // Sell
        }
        else
        {
            loK[shift] = 0;
            upK[shift] = EMPTY_VALUE; // Buy
        }
    }

    if (((TriggerCandle > 0) && (Time[0] > LastAlertTime)) || (TriggerCandle == 0))
    {
        string Text;
        // Outside Alert
        if ((loK[TriggerCandle] == 0) && (LastAlertDirection != 1))
        {
            if (LastAlertDirection != 0) // Skip actual alerts if it is the first run after attachment.
            {
                Text = "BB Squeeze: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - BB Outside Keltner.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("BB Squeeze Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
            }
            LastAlertTime = Time[0];
            LastAlertDirection = 1;
        }
        // Inside Alert
        if ((upK[TriggerCandle] == 0) && (LastAlertDirection != -1))
        {
            if (LastAlertDirection != 0) // Skip actual alerts if it is the first run after attachment.
            {
                Text = "BB Squeeze: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - BB Inside Keltner.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("BB Squeeze Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
            }
            LastAlertTime = Time[0];
            LastAlertDirection = -1;
        }
    }

    return rates_total;
}
//+------------------------------------------------------------------+