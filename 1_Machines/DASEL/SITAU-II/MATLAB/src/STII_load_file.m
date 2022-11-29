function [acqdata cfg]=STII_load_file (f_name)

%[acqdata cfg]=STII_load_file (f_name)
%
%Lee datos adquiridos con el equipo SITAU-II y guardados en el archivo
%especificado.
%
%f_name: nombre del archivo de datos (se ignora la extension)
%
%acqdata: Datos capturados. Es una matriz de 
%         n_samples x n_ascan x n_focal_law x n_acquisitions.
%         si solo se ha adquirido una
%         n_samples x n_ascan x n_focal_law 
%
%cfg es una estructura con informacion de las condiciones de adquisiciï¿½n.
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
%ver.:  1.0
%07/11/2022
%A. Ibáñeez  ITEFI-CSIC


%% ENTRADA 
% Entre el primer prototipo y los siguientes se cambio la etiqueta base
% del archivo descriptivo XML. Desde aqui se redirecciona la funcion
% adecuada

% *** PROCESSING PARAMETERS *****
[senda, nombre, ext]=fileparts(f_name);
filename = fullfile(senda, nombre);

% *** ACQUISITION PARAMETERS ***
 
xml = xml2struct([filename '.xml']); 
%%
%Verifica que existan las ramas que se quieren leer
if (isfield (xml, 'STLIB2')==true)
    [acqdata cfg]=STII_load_file_STLIB2(filename, xml);
elseif (isfield (xml, 'STFPLIB2')==true)
    [acqdata cfg]=STII_load_file_STFPLIB2(filename, xml);
else
    error('El archivo XML no tiene el formato esperado');   
end
