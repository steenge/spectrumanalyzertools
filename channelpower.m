function res = channelpower(IP, tech, ch, bw, NoSamples, notes)

pauseShort=0.15;
sb = 20; % sb [MHz] added to freq span on each side of bw

% tech = 24 / 5
% ch = 1-13 OR 36-140 depending on tech
% NoSamples = number os sales to measure. result will be mean(samples)
% bw = if tech=24, bw = 20, 40 # if tech = 5, bw = 40, 80, 160

switch (tech)
    case 24,
        switch (ch)
            case 1, Fc = 2.412;
            case 2, Fc = 2.417;
            case 3, Fc = 2.422;
            case 4, Fc = 2.427;
            case 5, Fc = 2.432;
            case 6, Fc = 2.437;
            case 7, Fc = 2.442;
            case 8, Fc = 2.447;
            case 9, Fc = 2.452;
            case 10,Fc = 2.457;
            case 11,Fc = 2.462;
            case 12,Fc = 2.467;
            case 13,Fc = 2.472;
            otherwise,
                disp('when tech is 24, ch must be 1-13');
                res=0;
                return;
        end
        if ~(bw == 20 || bw==40)
            disp('Warning: For tech=24, bw must be 20 or 40')
%            res=0;
%            return;
        end        
    case 5,
        switch (ch)
            case 36,  Fc = 5.180;
            case 40,  Fc = 5.200;
            case 44,  Fc = 5.220;
            case 48,  Fc = 5.240;
            case 52,  Fc = 5.260;
            case 56,  Fc = 5.280;
            case 60,  Fc = 5.300;
            case 64,  Fc = 5.320;
            case 100, Fc = 5.500;
            case 104, Fc = 5.520;
            case 108, Fc = 5.540;
            case 112, Fc = 5.560;
            case 116, Fc = 5.580;
            case 120, Fc = 5.600;
            case 124, Fc = 5.620;
            case 128, Fc = 5.640;
            case 132, Fc = 5.660;
            case 136, Fc = 5.680;
            case 140, Fc = 5.700;
            otherwise,
                disp('when tech is 5, ch must be 36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140');
                res=0;
                return;
        end
        if ~(bw == 40 || bw==80 || bw==160)
            disp('Warning: For tech=5, bw must be 40, 80 or 160')
%            res=0;
%            return;
        end
    otherwise,
        disp('tech must be 24 or 5');
        res=0;
        return;
end

disp(['Measurement settings derived: Fc=' num2str(Fc) ' GHz, bw=' num2str(bw) ' MHz, res=mean(' num2str(NoSamples) ')'])
disp(['Notes for this test: ' notes])

%% configuring instrument

addpath('tcpip/')
addpath('instr/')

t = tcpip(IP, 5025);

t.write('REN');
pause(pauseShort)
t.write('*RST');
pause(2)

%% Set parameters

% center frequency Fc
t.write(['CF ' num2str(Fc) 'GZ']);
pause(pauseShort)

% frequency span
t.write(['SP ' num2str(bw+2*sb) 'MZ']);
pause(pauseShort)

% Detector AVG
pause(pauseShort)
t.write(['DETPOS']);

% dB per DIV
pause(pauseShort)
t.write(['DD6']);

% ref level
pause(pauseShort)
t.write(['RL-16']);


pause(pauseShort)
t.write(['CALCAMAX']);
pause(pauseShort)

garbage0=t.read(); % tøm buffer
pause(pauseShort)

for idx=1:NoSamples

    t.write('PMEASAVG OFF');
    pause(0.5)
    t.write('PMEASAVG ON');
    t.write('PMEASTRACE TRA');
    t.write('PWCHTM 200');
    t.write('PMEASAVGONCE ONCE');
    t.write(['WDX ' num2str(bw) ' MZ']);
    t.write(['PWCHON ON']);

    pause(15);

    garbage0=t.read(); % tøm buffer
    pause(pauseShort)
    chPwr(idx) = readParm(t, 'PWCH?');

    disp(['Measurement #' num2str(idx) ': ' num2str(chPwr(idx)) ' dBm'])
end
t.close();

res=mean(chPwr);