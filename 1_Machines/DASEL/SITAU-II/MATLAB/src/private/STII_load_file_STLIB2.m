function [acqdata cfg]=STII_load_file_STLIB2 (archivo, xml)

%[acqdata cfg]=STII_load_file_STLIB2 (archivo)


%Tras el primer prototipo cambiaron la estructura y nombre de etiquetas del
%archivo XML. Esta funcion lee los archivos con etiqueta base STLIB2
%function [acqdata cfg]=SITAU_leer_archivo (archivo)
%
%Lee datos adquiridos con el equipo SITAU y guardados en el archivo
%especificado.
%
%archivo: nombre del archivo de datos (se ignora la extensi�n)
%
%acqdata: Datos capturados. Es una matriz de 
%         n_samples x n_ascan x n_focal_law x n_acquisitions.
%         si solo se ha adquirido una
%         n_samples x n_ascan x n_focal_law 
%
%cfg es una estructura con informacion de las condiciones de adquisici�n.
%Esta formada por los siguientes campos:
% filename          -> Just that
% date_time         -> Just that
% sitau_ver         -> SITAU file version
% f_probe           -> Nominal frequecy of the used Array (MHz)
% pitch             -> Array pitch (mm)
% Nel               -> Number of elements in the array
% acq_type          -> FMC, PWI, OTHER
% n_acquisitions    -> Number of acquired images
% n_focal_law       -> Number of focal laws (emissions) per image (=length of th in PWI)
% n_ascan           -> Number of received A-Scans in each emission
% n_samples         -> Number of samples per channel
% fs                -> Sampling frequency MHz
% n_bits            -> Number of bits of the A/D converter
% PRF               -> Plane waves PRF (kHz)
% n_average         -> Number of averages per focal law
% c                 -> Sound velocity (m/s)   ---ATENCION---
% start_dist        -> Adquisition start distance (mm)
% end_dist          -> Adquisition end distance (mm)
% th                -> PW angles (deg) for PWI, zero otherwise 
% wd                -> Array lens delay (us)
% gain              -> Analog gain (dB)
% Z_act             -> Active termination impedance (Ohm)
% tau_s             -> ----
% dly_0             -> Delay of element 0 (us)
% water_delay_ticks -> ---
%
%ver.:  1.0.2
%22/11/2022
%A. Ibanez  ITEFI-CSIC


%% ESTO ESTA ACTIVO EN LA FUNCION BASE: SITAU_leer_archivo(archivo)

% % % *** PROCESSING PARAMETERS *****
% % [senda, nombre, ext]=fileparts(archivo);
% % filename = fullfile(senda, nombre);
% % 
% % 
% % % *** ACQUISITION PARAMETERS ***
% % 
% % xml = xml2struct([filename '.xml']); 

filename=archivo;
%%
%Verifica que existan las ramas que se quieren leer
xml_vale = (isfield (xml, 'STLIB2')==true) &&...
    (isfield (xml.STLIB2, 'Version')==true) &&...
    (isfield (xml.STLIB2.Version, 'Parameter')==true) &&...
    (isfield (xml.STLIB2, 'VirtualChannel')==true) &&...
    (isfield (xml.STLIB2.VirtualChannel, 'UT_Parameters')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.UT_Parameters, 'Parameter')==true)&&...
    (isfield (xml.STLIB2.VirtualChannel, 'DSP')==true)&&...    
    (isfield (xml.STLIB2.VirtualChannel.DSP, 'Parameter')==true)&&...     
    (isfield (xml.STLIB2.VirtualChannel, 'AFE')==true)&&...    
    (isfield (xml.STLIB2.VirtualChannel.AFE, 'SPI')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.SPI, 'REG51')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.SPI.REG51, 'Register')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.SPI, 'REG52')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.SPI.REG52, 'Register')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.SPI, 'REG59')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.SPI.REG59, 'Register')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE, 'BUSSAR')==true)&&... 
    (isfield (xml.STLIB2.VirtualChannel.AFE.BUSSAR, 'Register')==true);

%...  por ahora el resto de campos me la pelan...
% xml_vale = xml_vale && (isfield (xml.STLIB2.VirtualChannel, 'PA_FocalLaw')==true);       
% xml_vale = xml_vale && (isfield (xml.STLIB2.VirtualChannel, 'DSP')==true);


if xml_vale==false
    error('El archivo XML no tiene el formato esperado');   
end

cfg=struct('filename',{},'date_time', {},'sitau_ver',{},...
           'f_probe',{},'pitch',{}, 'Nel', {},...
           'acq_type',{},'n_acquisitions',{},'n_focal_law',{},'n_ascan',{},...
           'n_samples',{},'fs',{},'dec_rat',{},'n_bits',{},'PRF',{},'n_average',{},...
           'c',{},'start_dist',{},'end_dist',{},'th',{},'gain',{},...
           'Z_act',{},'lfp',{},'wd',{},'tau_s',{}, 'dly_0',{});  


cfg(1).filename=filename;
cfg.n_bits = 16;  %numero de bits del conversor A/D

%% Datos relativos a la version 
file_ver=xml.STLIB2.Version.Parameter;

% No me apetece verificar la existencia de todos los campos, si revienta y 
% molestara o molestase lo metiere en un try....
if iscell(file_ver)    %Por si alg�n d�a crece...
    for i=1:length(file_ver)
        switch file_ver{1,i}.Attributes.pName
            case {'XML File Version'}
                cfg.sitau_ver=str2double(file_ver{1,i}.Attributes.pValue);  
                
%             case {''}
%                 cfg.XXX=str2double(file_ver{1,i}.Attributes.pValue);  %
        end
    end
else
     cfg.sitau_ver=str2double(file_ver.Attributes.pValue);
end
%% Datos relativos a los par�metros de ultrasonidos de la adquisicion

ut_p=xml.STLIB2.VirtualChannel.UT_Parameters.Parameter;
% No me apetece verificar la existencia de todos los campos, si revienta y 
% molestara o molestase lo metiere en un try....

for i=1:length(ut_p)
    switch ut_p{1,i}.Attributes.pName
        case {'(FP) Focal Law type'}
            switch str2double(ut_p{1,i}.Attributes.pValue); %Dataset type
                case 1
                    cfg.acq_type = 'FMC';
                    angulos = false;
                case 2
                    cfg.acq_type = 'PWI';
                    angulos=true;
                otherwise
                    cfg.acq_type = 'OTHER';
                    angulos = false;
            end
        case {'(FP) PWIC Start Angle []', '(FP) PWIC Start Angle [deg]'}
            a_ini=str2double(ut_p{1,i}.Attributes.pValue);  %PW angles          
        case {'(FP) PWIC End Angle []', '(FP) PWIC End Angle [deg]'}
            a_end=str2double(ut_p{1,i}.Attributes.pValue);  %PW angles          
        case {'(FP) PWIC Step Angle []', '(FP) PWIC Step Angle [deg]'}
            a_step=str2double(ut_p{1,i}.Attributes.pValue); %PW angles
        case {'PRF Frequency [Hz]'}
            cfg.PRF=str2double(ut_p{1,i}.Attributes.pValue)*1e-3;  %PRF khZ
        case {'Material Velocity [m/s]'}
            cfg.c=str2double(ut_p{1,i}.Attributes.pValue);  %Longitudinal wave part velocity (mm/us)            
        case {'Acq. Start Distance [mm]'}
            cfg.start_dist=str2double(ut_p{1,i}.Attributes.pValue); %Distance (mm) at which the acquisition begins            
        case {'Acq. End Distance [mm]'}
            cfg.end_dist=str2double(ut_p{1,i}.Attributes.pValue); %Distance (mm) at which the acquisition ends 
        case {'Acq. Distance [mm]'}  %si pone esto es un archivo PWI antiguo...
            cfg.start_dist=0; %Distance (mm) at which the acquisition begins            
            cfg.end_dist=str2double(ut_p{1,i}.Attributes.pValue); %Distance (mm) at which the acquisition ends 
        case {'Probe Elements Number'}
            cfg.Nel=str2double(ut_p{1,i}.Attributes.pValue);  %Number of active channels
        case {'Probe Pitch [mm]'}
            cfg.pitch=str2double(ut_p{1,i}.Attributes.pValue);  %Pitch (mm) 
        case {'Probe Frequency [MHz]'}
            cfg.f_probe=str2double(ut_p{1,i}.Attributes.pValue);  %frequency MHz 
            
%         case {''}
%             cfg.XXX=str2double(ut_p{1,i}.Attributes.pValue);  %            
    end  
end

%PW angles: 
if angulos==true;
    cfg.th = a_ini:a_step:a_end;
else
    cfg.th=0;
end

%% Datos relativos a los par�metros del  DSP
cfg.fs = 62.5; %sampling frequency MHz  EL PRIMER PROTOTIPO IBA A 50MHz 
               %desde la version  2.0 este valor se obtiene en DSP
               %y sobreescribe esta asigancion.

DSP=xml.STLIB2.VirtualChannel.DSP.Parameter;
for i=1:length(DSP)
    switch DSP{1,i}.Attributes.pName
        case {'Sampling Frequency [MHz]'}
            cfg.fs=str2double(DSP{1,i}.Attributes.pValue);  %          
        
%         case {''}
%             cfg.XXX=str2double(DSP{1,i}.Attributes.pValue);  %            
    end     
end
%% Datos relativos a los par�metros del  AFE.SPI


%REG51
SPI_R51=xml.STLIB2.VirtualChannel.AFE.SPI.REG51.Register;
% No me apetece verificar la existencia de todos los campos, si revienta y 
% molestara o molestase lo metiere en un try....

for i=1:length(SPI_R51)
    switch SPI_R51{1,i}.Attributes.pName      
        case {'LPF_PROGRAMMABILITY'}
            switch str2double(SPI_R51{1,i}.Attributes.pValue);  %AFE low-pass filter
                case 0
                    cfg.lfp = '15 MHz';
                case 2
                    cfg.lfp = '20 MHz';
                case 3
                    cfg.lfp = '30 MHz';
                case 4
                    cfg.lfp = '10 MHz';
                otherwise
                    cfg.lfp = 'unknown';
            end
        case {'PGA_GAIN_CONTROL'}
            switch str2double(SPI_R51{1,i}.Attributes.pValue) 
                case 0
                    g_pga=24;   %Analog gain (dB)
                case 1
                    g_pga=30;   %Analog gain (dB)
            end
%         case {''}
%             cfg.XXX=str2double(SPI_R51{1,i}.Attributes.pValue);  %            
    end 
end


%REG52
SPI_R52=xml.STLIB2.VirtualChannel.AFE.SPI.REG52.Register;
% No me apetece verificar la existencia de todos los campos, si revienta y 
% molestara o molestase lo metiere en un try....

for i=1:length(SPI_R52)
    switch SPI_R52{1,i}.Attributes.pName
        case {'LNA_GAIN'}
            switch str2double(SPI_R52{1,i}.Attributes.pValue) 
                case 0
                    g_lna=18;
                case 1
                    g_lna=24;
                case 2
                    g_lna=12;
            end
        case {'ACTIVE_TERMINATION_ENABLE'}
            act_term=str2double(SPI_R52{1,i}.Attributes.pValue);  %Active input termination
        case {'PRESET_ACTIVE_TERMINATIONS'}
            act_term_val=str2double(SPI_R52{1,i}.Attributes.pValue);  %Active input termination    

%         case {''}
%             cfg.XXX=str2double(SPI_R52{1,i}.Attributes.pValue);  %            
    end
end
%Active input termination:
if act_term == '1'    
    switch act_term_val
        case '0'
            cfg.Z_act = '50 ohm';
        case '1'
            cfg.Z_act = '100 ohm';
        case '2'
            cfg.Z_act = '200 ohm';
        case '3'
            cfg.Z_act = '400 ohm';
        otherwise
            cfg.Z_act = 'NPI ohm';    
    end
else
    cfg.Z_act = 'Hi_Z';
end


%REG59
SPI_R59=xml.STLIB2.VirtualChannel.AFE.SPI.REG59.Register;
% No me apetece verificar la existencia de todos los campos, si revienta y 
% molestara o molestase lo metiere en un try....

for i=1:length(SPI_R59)
    switch SPI_R59{1,i}.Attributes.pName
        case {'DIG_TGC_ATT_GAIN'}
            dig_tgc_g=str2double(SPI_R59{1,i}.Attributes.pValue); %Digital attenuator parte 1
        case {'DIG_TGC_ATT'}
            switch str2double(SPI_R59{1,i}.Attributes.pValue) 
                case 1
                    dig_tgc=-6;   %Digital attenuator parte 2
                otherwise
                    dig_tgc=0;   %Digital attenuator parte 2
            end
            
%         case {''}
%             cfg.XXX=str2double(SPI_R59{1,i}.Attributes.pValue);  %
    end
    
end

%Analog gain(dB) 
cfg.gain = g_lna + g_pga + dig_tgc * dig_tgc_g;


%% Datos relativos a los par�metros del  AFE.BUSSAR

BUSSAR=xml.STLIB2.VirtualChannel.AFE.BUSSAR.Register;
% No me apetece verificar la existencia de todos los campos, si revienta y 
% molestara o molestase lo metiere en un try....

for i=1:length(BUSSAR)
    switch BUSSAR{1,i}.Attributes.pName
        case {'DEC_RATIO'}
            cfg.dec_rat=str2double(BUSSAR{1,i}.Attributes.pValue);  %  
        case {'WATER_DELAY'}
            cfg.water_delay_ticks=str2double(BUSSAR{1,i}.Attributes.pValue);  %�?       
        case {'LOG2_AVERAGE'}
            cfg.n_average=2^str2double(BUSSAR{1,i}.Attributes.pValue);  %Averaging <- Falta leer el promediado del 
            
%         case {''}
%             cfg.XXX=str2double(BUSSAR{1,i}.Attributes.pValue);  %     
    end    
end

%%  OTROS VALORES DE CONFIGURACION QUE NO SE LEEN DEL .XML  

cfg.wd = .5; %wedge delay
cfg.tau_s = 17; %System delay in samples
% cfg.fs = 62.5; %sampling frequency MHz
cfg.dly_0 = (cfg.Nel-1)*cfg.pitch*sind(cfg.th)/cfg.c.*(cfg.th<0) - cfg.wd; %Delay of element 0
if cfg.sitau_ver ==1
    baraje    = [1 3 2 4 5 7 6 8 9 11 10 12 13 15 14 16 17 19 18 20 21 23 22 24 26 28 25 27 30 32 29 31];  %Aplicables para la version 1.0 del XML
end


%% LECTURA DESDE EL ARCHIVO .BIN

fid = fopen([cfg.filename '.bin'],'rb');
if fid ==-1
    error ('Binary file not found');
end
%Caracter de control:
format_type = fread(fid,1,'uint16');
switch format_type
    case 4660     % Little Endian 
        
    case 13330    % Big Endian
        fclose(fid);
        fid = fopen([cfg.filename '.bin'],'rb','b');
        format_type = fread(fid,1,'uint16');
        if format_type ~= 4660
            error('Format File Error');
        end
    otherwise
        error('Format File Error');
end

% Time
str_size = fread(fid, 1, 'int32');
cfg.date_time = fread(fid, [1,str_size], 'char=>char');
% fprintf(1,'%s\n',cfg.date_time);
% Signal Range Max. Amplitude
max_signal = fread(fid, 1, 'int32');
% Signal Range Min. Amplitude
min_signal = fread(fid, 1, 'int32');
% Number of acquisition
cfg.n_acquisitions = fread(fid, 1, 'int32');
% Number of Focal Law 
cfg.n_focal_law = fread(fid, 1, 'int32');

%todo lo que sigue tiene que ver con acquisiciones y disparos, aparte de
%los datos �hay parametros que cambian de un disparo a otro? Si es as� hay
%que generar un array de parametros, cada elemento ligado a un disparo.

canxmod=32;  %Cada modulo sitau tiene 32 canales
for i=1:cfg.n_acquisitions
    for j=1:cfg.n_focal_law  
        % Numver of A-Scan Signals 
        cfg.n_ascan = fread(fid, 1, 'int32');
        % Samples Number
        cfg.n_samples = fread(fid, 1, 'int32');   %SI CADA EN CADA ADQUISICION PUEDE CAMBIAR HAY QUE MODIFICAR ESTE CAMPO
        %TGC
        if i==1 && j==1
            
% Por ahora esto no se usa en ninguna parte as� que fuera            
%             tacq = (cfg.n_samples-1)/cfg.fs;     %Acquisiton time in us
%             alfa_tgc = cfg.att*cfg.f_probe*cfg.c/10;%TGC slope dB/us
%             Gfin = alfa_tgc*tacq; %Final gain
%             TGC_dB = [0:cfg.n_samples-1]/(cfg.n_samples-1)*tacq*alfa_tgc; %TGC curve in dB
%             TGC_lin = 10.^(TGC_dB/20); %TGC curve in linear scale
%             TGC_m = int16(repmat(TGC_lin',1,128));
            n_mod=floor(cfg.n_ascan/32);  %numero de modulos en este sitau (si no es entero vendr� el caos)
            acqdata = zeros(cfg.n_samples, cfg.n_ascan, cfg.n_focal_law,cfg.n_acquisitions);
        end
%%       
        % Focal Law Image Size
%         image_size = [1 fread(fid, 1, 'int32')];   %debe ser: cfg.n_samples * cfg.n_ascan
        image_size = fread(fid, 1, 'int32');   %debe ser: cfg.n_samples * cfg.n_ascan

        % Focal Law Image
        data = fread(fid, image_size, 'int16');

        if (image_size > 0)           
            if cfg.sitau_ver==1.0
                img = reshape(data,32,cfg.n_samples*n_mod);
                img=reshape(img(baraje,:),canxmod,cfg.n_samples,n_mod); 
                img=permute(img,[2,1,3]);
                acqdata(1:end-cfg.tau_s+1,:,j,i) =img(cfg.tau_s:end,:);  %EN MATLAB LA VIDA PASA EN DOUBLE SI ALGUIEN LO QUIERE INT16 QUE LO HAGA EL
            else
                img=reshape(data,cfg.n_samples,cfg.n_ascan); 
                acqdata(1:end-cfg.tau_s+1,:,j,i) =img(cfg.tau_s:end,:);  %EN MATLAB LA VIDA PASA EN DOUBLE SI ALGUIEN LO QUIERE INT16 QUE LO HAGA EL
            end
            
           

            
        end        
    end       

%     disp(cfg.n_acquisitions - i);
end
fclose(fid);

acqdata=squeeze(acqdata);
%cfg.n_samples = cfg.n_samples - cfg.tau_s + 1; %si esto es as� que sentido tiene mantener tau_s en cfg?
                                                %DE HECHO EL NUMERO DE DATOS LEIDOS Y DEVUELTOS ES EL cfg.n_samples que se lee del .bin        
%cfg.n_samples=size(acqdata,1);

