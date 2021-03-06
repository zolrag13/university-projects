clear all;
close all;
clc;
figure;
hold on;

%Variables physiques
global frequence  eps_0  mu_0  sigma  R_a P_TX lambda B h_e epsR l Zcable; 
%Variables de localisation
global vec TX crois champ hauteurPlan longueurPlan dessin pasR; 

frequence = 2.45E9;                             %fr�quence du r�seau 802.11n [GHz]
sigma = 0.1;                                    %conductivit� du mur [S/m]
epsR = 5;                                       %permittivit� relative du mur
l    = 0.1;                                     % Epaisseur de mur
R_ar = 73;
R_al = 0;
R_a = R_ar + R_al;                                       %R�sistance d'antenne [Ohms]
eps_0 = 8.854E-12;                              %Permittivit� du vide [F/m]
mu_0 = pi*4E-7;                                 %Perm�abilit� du vide [H/m]
P_injectee = 10;                                %Puissance inject�e dans l'antenne [dBm]
longueuerCable = 1;                             % [m]
Attenuation = 1;                                %Att�nuation dans le c�ble [dB/m]
Zcable = 50;
P_TX = 7.94E-3;                                 %Puissance �mise par l'antenne [W]
                                                 %Puissance : en d�cibel --> P[dBm] = 10 log P[W]/1mW
lambda = 1/(sqrt(eps_0*mu_0)*frequence);
B = 2*pi/lambda;
thetaRepere = pi/2;                              %pour un rep�re sph�rique nous sommes dans le cas theta = pi/2
h_e = - lambda/pi * ...                          % hauteur equivalente = -lambda/pi apr�s simplification
    cos(pi/2 * cos(thetaRepere))/(sin(thetaRepere))^2;                                                

%Chargement du plan
hauteurPlan = 46+1;
longueurPlan = 42+1;
vec = Plan;
% hauteurPlan = 10+1;
% longueurPlan = 20+1;
% vec = planSimple;


% TXTab = [ 8 2  ; 12 4 ; 5 21.5 ; 5 31.5 ; 2.5 40 ;  6 34.5 ; 8.5 36 ; 20.5 36; 30.5 36; 33 16.5 ; 31.5 4; 35 25.5 ;35 15.5 ;35 5.5 ; 6 23 ; 6 34.5;    23 35 ;  34 35 ; 13 2 ;  34 2.5; 34 22 ];
%
%TXTab = [ 22.5 35.5; 13.5 3; 34 15 ; 6 26; 41 40; 34 40; 5 10; 5 20];
% TXTab = [ 1.25 1.25 ; 5.25 5.25 ; 12.25 8.25 ; 12.5 1];


TXTab = [];
% TXTab = [ 30 30; 20 40; 10 27; 5 33; 10 40; 37 20; 10 10; 27 40];
%intersection entre les murs et aretes des portes 
crois = croisements;
[ptinit ptfin] = aretesPortes;

%vecteurs contenant les puissances et d�bits en chaque point pour chaque
%position de l'�metteur
vecPuissance = zeros(42,46);
vecDebit = zeros(42,46);
Resultat = {};
counter = 1 ;

tic
left1 = 400;
bottom1 = 100;
width1 = 275; 
height1 = 70;
rect1 = [left1, bottom1, width1, height1];

left2 = 100;
bottom2 = 100;
width2 = 275; 
height2 = 70;
rect2 = [left2, bottom2, width2, height2];

pasEH = 4;
pasEV = 8;
pasR = 1;
dessin = false;
h = waitbar ( 1/length(TXTab) , 'Emetteurs', 'OuterPosition', rect1);
for r = 2:pasEH: longueurPlan-1
    for f = 3 :pasEV: hauteurPlan-1
        TXTab = [TXTab; [r f]];
    end
end

for o = 1 : length(TXTab)
    waitbar ( o / length(TXTab ) , h)
    m = TXTab(o,1);
    n = TXTab(o,2);
    %Vérifie qu'on est pas sur un mur avant de positionner le récepteur
    eSurLeMur = false;
    for k = 1 : length(vec)
        if vec(k,1) <= m && vec(k,2) <= n && m <= vec(k,3)  &&  n <= vec(k,4)
            eSurLeMur = true;
            break;
        end
    end
%         %Vérifie aussi qu'on est pas en zone rouge avant de placer le
%         %récepteur
    eDansZoneRouge = (m >= 13 && n >= 4 && n <= 34 && m <= 27);
%         eDansZoneRouge = false;
    if ~eDansZoneRouge  
      if~eSurLeMur  
        TX = [m n];
        %Matrice des r�sultats contenant le champ recu au recepteur
        champ = zeros (longueurPlan,hauteurPlan);
        %Dessin emetteur 
        plot(TX(1), TX(2), 'black', 'Marker', '.', 'MarkerSize' ,20); 

        %parcourt le plan complet avec le recepteur
        p = waitbar ( 1/longueurPlan, 'Recepteurs', 'OuterPosition', rect2);
        for i = 1.5  : pasR : longueurPlan
            waitbar(i/longueurPlan, p )
            
            for j = 1.5  : pasR : hauteurPlan        
                %Vérifie aussi qu'on est pas en zone rouge avant de placer le
                %récepteur
                RX = [i-1 j-1];
               rDansZoneRouge = (RX(1) >= 13 && RX(2) >= 4 && RX(2) <= 34 && RX(1) <= 27);
%                    rDansZoneRouge = false;
                if ~rDansZoneRouge   
                    %reflexions
                    reflexionDouble(TX,RX,1);
                    reflexionSimple(TX,RX,1);
                    ondeDirecte(TX,RX,1);
                    diffraction(TX, RX, ptinit, ptfin);
                end
            end 
        end   
        close(p) 
        vecPuissance = calculPuissance;
        vecDebit = calculDebit(vecPuissance);
        Resultat{counter} = { vecPuissance vecDebit TX };
        counter = counter+1 ;  
      end  
    end  
end
close(h)
toc
tic
gereResultats(Resultat);
toc

%PARAMETRES: 
%cable: 1m
%       impédance caractéristique: omega = 50 ohms
%       atténuation : 1dB/m
%antenne : dipole lambda/2 sans perte pas adaptée
