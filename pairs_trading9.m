% pairs_trading_9.m

% clear
clear all
close all
clc

%Load data
Sfull = load('Pairs_HistPrices.csv') ;
[N,z] = size(Sfull)

%Parametros
windowSize = 63 ;%numero de rendimientos
dt = 1/252 ;
stdOpen = 2.0 ;
stdClose = 1.0 ;

%Numero de ventanas
Nwindows = N - windowSize - 1 ;

%Valores iniciales de la estrategia
openShort(1) = 0 ;
openLong(1) = 0 ;

for w = 1:Nwindows
    S = Sfull(w : w + windowSize , : ) ;
    R = (S(2:end,:)-S(1:end-1,:))./S(1:end-1,:);
    
    %Correr regresion lineal de rendimientos
    x = R(1:windowSize,2) ;
    y = R(1:windowSize,1) ;
    [P,m,b] = regression( x' ,y') ;
    error = y-(b + m*x);
    beta(w) = m ;
    
    %Calcular proceso autoregresivo
    X = cumsum(error);
    
    %Calcular score
    x = X(1:end-1) ;
    y = X(2:end);
    [P,a,b] = regression( x' ,y') ;
    
    k(w) = (1-a)/dt ; 
    m(w) = b/(1-a) ;
    tau(w) = 1/(k(w)*dt) ;
    xi = (y -(b+a*x));
    sigma2(w) = var(xi)/dt ;
    sigma2_eq(w) = var(xi)/(1-a^2);
    score(w) = (X(end)- m(w))/sqrt(sigma2_eq(w));
    
    %Estrategia
    if ( (openShort(w) < 0.5)  && (openLong(w) < 0.5 ))
        % Ambos portafolios cerrados
        openShort(w+1) = 0 ;
        openLong(w+1) = 0 ;
        if (score(w) > stdOpen)
            %Sell to open
            openShort(w+1) = 1 ;
            betaOpen(w+1) = beta(w) ; 
        end
        
        if (score(w) < -stdOpen)
            %Buy to open
            openLong(w+1) = 1 ;
            betaOpen(w+1) = beta(w) ;
        end
           
    else
        % Un portafolio abierto
        betaOpen(w+1) = betaOpen(w) ;
        openShort(w+1) = openShort(w) ;
        openLong(w+1) = openLong(w) ;
        
        if (openShort(w) > 0.5)
            if ( score(w) < stdClose )
                openShort(w+1) = 0 ;
            end            
        end
        
        if (openLong(w) > 0.5)
            if ( score(w) > -stdClose )
                openLong(w+1) = 0 ;
            end            
        end
        
    end    
end
plot(score)
title('Score')
xlabel('ventana')
hold on
plot(1:Nwindows , stdOpen , 'g')
plot(1:Nwindows , -stdOpen , 'g')
plot(1:Nwindows , stdClose , 'r')
plot(1:Nwindows , -stdClose , 'r')

figure
plot(openLong-openShort)

%Calcular P&L
% PL = (openShort(w+1)- openShort(w))*S() .......



