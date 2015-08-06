
NoSamples = 1000;

pauseShort=0.15;
pauseLong=5;
MonitorTime=30;

Fstart = 5.10;
Fstop = 5.70;


addpath('tcpip/')
addpath('instr/')
%addpath('gpipio/')


t = tcpip('192.168.1.75', 5025);

t.write('REN');
pause(pauseShort)
t.write('*RST');
pause(2)

% set start, stop freq
t.write(['FA ' num2str(Fstart) 'GZ']);
pause(pauseShort)
t.write(['FB ' num2str(Fstop) 'GZ']);

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


dBperDiv = readParm(t, 'DDB?');
refLevel = -16;
dRefUnit = readParm(t, 'AUNITS?');


%pause(MonitorTime)

t.write('DLIM0');
pause(pauseShort)

garbage0=t.read(); % tøm buffer
pause(pauseShort)
tic
x=1;
for i=1:NoSamples
    try
        pause(pauseShort)
        t.write(['SR']);
        pause(pauseShort)
        nope=t.read();
        pause(pauseShort)
        t.write('TAA?');
        pause(1.5)
        tmp = t.read();
        res = strread(tmp, '%d', 'delimiter', ' ');
        tmp1 = (res-1792)/(14592-1792); % Skaler til 0:1 intervallet
        if (length(tmp1) == 1001)
            disp(['ok, ' num2str(100*(x/NoSamples)) '% complete'])
            samples{x}=(tmp1*10*dBperDiv)+(refLevel-(10*dBperDiv)); % Skaler til skærmformat, reflevel og antal db per div afgør område    
            time(x)=toc;
            x=x+1;
        else
            disp(['vector size deviates from expected (1001), actual size is ' num2str(length(tmp1))])
        end
    catch
        disp(['Crash'])
    end
    pause(pauseShort)
    t.write(['SR']);

end

%*****************




t.close();

samples = cell2mat(samples);

figure;hold;

g=size(samples);

for i=1:g(2)
    plot(Fstart:(Fstop-Fstart)/1000:Fstop, samples(:,i), 'k', 'LineWidth', 1)
end

minVal = min(min(samples)); 
maxVal = max(max(samples));

axis([Fstart Fstop minVal maxVal])

%plot(Fstart:Fstop, res)
grid
xlabel('Frequency [GHz]')
ylabel('Power [dBm]')

for i=0:12

    pb = patch([(2.412+i*0.005)-0.002 (2.412+i*0.005)+0.002 (2.412+i*0.005)+0.002 (2.412+i*0.005)-0.002], [minVal minVal maxVal maxVal],'r','edgecolor','none');
    alpha(pb,.1);
    
    plot([2.412+i*0.005 2.412+i*0.005], [minVal maxVal], 'r:', 'LineWidth', 2)
%    rectangle('Position', [(2.412+i*0.005)-0.01, 6500, 0.02 3500+i*100])
end

title(['5 GHz full channel scan series, MaxHold, N=' num2str(NoSamples) 'samples collected'])

figure;
surf(samples', 'FaceColor', 'interp', 'EdgeColor', 'none');
view(290,20)

xticklabels=round(Fstart*100)/100:round(100*(Fstop-Fstart)/9)/100:round(100*Fstop)/100;
set(gca, 'Xtick', linspace(1,size(samples, 1), 10), 'XtickLabel', xticklabels)

yticklabels= 0:round(100*(time(length(time))/60)/10)/100:round(time(length(time))/60);
set(gca, 'Ytick', linspace(1,size(samples, 2), 10), 'YtickLabel', yticklabels)

ylabel('time [min]')
zlabel('Magnitude [dBm]')
xlabel('Frequency [GHz]')
title(['5 GHz full channel scan series, MaxHold, N=' num2str(NoSamples) ' samples collected'])



figure
imagesc(samples)
set(gca, 'Ydir', 'normal')
xlabel('time')
ylabel('Frequency')
colorbar
yticklabels=Fstart:(Fstop-Fstart)/9:Fstop;
set(gca, 'Ytick', linspace(1,size(samples, 1), 10), 'YtickLabel', yticklabels)

xticklabels= 0:round(100*(time(length(time))/60)/10)/100:round(time(length(time))/60);
set(gca, 'Xtick', linspace(1,size(samples, 2), 10), 'XtickLabel', xticklabels)

title(['5 GHz full channel scan series, MaxHold, N=' num2str(NoSamples) 'samples collected'])





