//+------------------------------------------------------------------+
//|                                                    Clarice01.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#define EXPERT_MAGIC 140322

input int fastPeriod = 10; // Período da SMA curta
input int slowPeriod = 50; // Período da SMA longa
input double lotSize = 0.01; // Tamanho do lote
input ENUM_TIMEFRAMES timeframe = PERIOD_M30; // Timeframe (intervalo de tempo)

double trailingStart = 0; // Preço a partir do qual o Trailing Stop será ativado
double trailingStopDistance = 50 * _Point; // Distância para o Trailing Stop em pontos
double maxCandleRange = 1000 * _Point; // Máxima faixa de vela em pontos para confirmação

void OnTick()
{
    if (_Period != timeframe) // Verifica se o intervalo de tempo é o desejado
        return;

    double fastMA = iMA(_Symbol, timeframe, fastPeriod, 0, MODE_SMA, PRICE_CLOSE);
    double slowMA = iMA(_Symbol, timeframe, slowPeriod, 0, MODE_SMA, PRICE_CLOSE);
    int spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD); //Substitui a função MarketInfo
    double candleRange = (SymbolInfoDouble(_Symbol, SYMBOL_POINT) + spread) * _Point;
    
    if (fastMA > slowMA && candleRange <= maxCandleRange)
    {
        // Condição de compra
        double openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        // Calcular os níveis de take profit e stop loss
        double takeProfitPrice = openPrice + 150 * _Point;
        double stopLossPrice = openPrice - 50 * _Point;
        
        MqlTradeRequest requestBuyOrder = {};
        MqlTradeResult resultBuyOrder = {};
        
        requestBuyOrder.action = TRADE_ACTION_DEAL;
        requestBuyOrder.symbol = _Symbol;
        requestBuyOrder.volume = lotSize;
        requestBuyOrder.type = ORDER_TYPE_BUY;
        requestBuyOrder.price = openPrice;
        requestBuyOrder.deviation = 3;
        requestBuyOrder.magic = EXPERT_MAGIC;
        requestBuyOrder.comment = "Buy Order";
        
        // Colocar a ordem de compra
        if (!OrderSend(requestBuyOrder, resultBuyOrder))
        {
            PrintFormat("OrderSend buy error %d",GetLastError());
        } else {
            PrintFormat("deal=%I64u  order=%I64u",resultBuyOrder.deal,resultBuyOrder.order);
            trailingStart = openPrice + trailingStopDistance;
        }
    }
    else if (fastMA < slowMA && candleRange <= maxCandleRange)
    {
        // Condição de venda
        double openPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Calcular os níveis de take profit e stop loss
        double takeProfitPrice = openPrice - 150 * _Point;
        double stopLossPrice = openPrice + 50 * _Point;

        MqlTradeRequest requestSellOrder = {};
        MqlTradeResult resultSellOrder = {};
        
        requestSellOrder.action = TRADE_ACTION_DEAL;
        requestSellOrder.symbol = _Symbol;
        requestSellOrder.volume = lotSize;
        requestSellOrder.type = ORDER_TYPE_SELL;
        requestSellOrder.price = openPrice;
        requestSellOrder.deviation = 3;
        requestSellOrder.magic = EXPERT_MAGIC;
        requestSellOrder.comment = "Sell Order";
        
        if (!OrderSend(requestSellOrder, resultSellOrder))
        {
            PrintFormat("OrderSend sell error %d",GetLastError());
        } else {
            PrintFormat("deal=%I64u  order=%I64u",resultSellOrder.deal,resultSellOrder.order);
            trailingStart = openPrice - trailingStopDistance;
        }
    }    
    
    if (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
    {
        double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double newStopLoss = trailingStart + trailingStopDistance;

        // Verificar se o preço atual é maior do que o preço do Trailing Start
        // E se o novo stop loss é menor do que o preço atual
        if (currentBid > trailingStart && newStopLoss < currentBid)
        {
            MqlTradeRequest requestModify = {};
            MqlTradeResult resultModify = {};

            requestModify.action = TRADE_ACTION_SLTP;
            requestModify.symbol = _Symbol;
            requestModify.position = PositionGetInteger(POSITION_TICKET);
            requestModify.sl = newStopLoss;
            requestModify.magic = EXPERT_MAGIC;

            // Atualizar o stop loss
            if (!OrderSend(requestModify, resultModify))
            {
                PrintFormat("OrderModify error %d", GetLastError());
            }
            else
            {
                PrintFormat("Stop Loss atualizado para: %.5f", newStopLoss);
            }
        }
    }
    
}
