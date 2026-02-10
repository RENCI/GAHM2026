%-------------------------------------------------------------------------
% Script to read in and parse ATCF format, ADCIRC/ASWIP fort.22 format or 
% extended ADCIRC fort.22 format TC track files
%
% Data is sent back to calling program in the ATCF2 data structure
%
% the input data file must end in either .txt, .csv, dat
%
% acceptable values for input_file_type are:
%     ATCF                  = standard ATCF - NOTE: not tested for recent
%                                                   versions of this code
%     ASWIP                 = standard fort.22 (ASWIP)
%     GAHM2026              = revised / extended fort.22 (written by
%                                                       write_fort22_ext.m)
%
% time is returned in datetime formats
% eye location returned in deg lon,lat (S,W = - lon,lat)
% all other variables returned in original units, i.e., 
%     Wind speed in knots
%     Pressure in milibars
%     Disances in nautical miles
% isotach radii are organized by quadrants clockwise from NE, i.e., 
%                                                    1:4 = NE, SE, SW, NW
%
% Version history:
% 2/26/2023 - original read_ATCF
% 
% 6/16/2024
% 1. An error was fixed that gave incorrect times when they spanned a month
%    boundary.
% 2. The returned data structure has a single entry for each time.  
%    The corresponding line in the datastructure contains all of the
%    timesnap information, including R34, R50, R64 and is easier to work 
%    with than the original version.
% 3. This recognizes both 'BEST' and 'CT00' (COAMPS-TC) as similar runtypes 
% 4. Additional variables are returned to make it easier to output to a
%    fort.22 file using the data structure.
%
% 10/23/2024
% 1. Changes to variable names and types to bring ATCF2 into alignment with
%    read_IBTrACS
% 
% 10/30/2024
% 1. Data structure reorganized
% 2. Input file type added
% 
% 5/1/2025
% 1. Fixed assignment of runtimemin_str to be a 2digit string
%
% 5/2/2025  
% 1. separated fort.22 formats into ASWIP and GAHM2026 variants
%
% 5/10/2025
% 1. added calculations of RmaxQ and Rmax_out for ASWIP fort.22 input
%
% 5/16/2025
% 1. distinguished between Vmax_Vor_1_tbl for ASWIP input and VmaxVor_10_tbl
%    for GAHM input
% 2. added the isotach=0 case
%
% 5/20/2025
% 1. bug fixes in B, Bg, VmaxVor output, numiso, flag00
% 2. converted stype & wincode to ' ' for missing values
%
% 8/1/2025
% 1. updated for new diagnostic flags, SVorQuad_10_tbl output, and Bg_tot
%  
%                Rick Luettich  8/1/2025
%
function ATCF2=read_ATCF_fort22(input_file,input_file_type)

earthRadiusInMeters=6371000;

ft_ATCF=false;
ft_ASWIP=false;
ft_GAHM2026=false;

if input_file_type == "ATCF"
    ft_ATCF=true;
elseif input_file_type == "ASWIP"
    ft_ASWIP=true;
elseif input_file_type == "GAHM2026"
    ft_GAHM2026=true;
else
    fprintf('\n Error in read_ATCF_fort22.m. input file type unrecogrnized. %s \n \n',input_file_type)
end

ATCF_data=readtable(input_file);

[rows cols]=size(ATCF_data);

% combine first two columns to make the storm designation

basin=char(table2array(ATCF_data(:,1)));
snum=table2array(ATCF_data(:,2));
if snum < 10
    snum_cha(:,2)=num2str(snum);
    snum_cha(:,1)='0';
else
    snum_cha=num2str(snum);
end
ATCF.basin=basin;
ATCF.snum=snum_cha;
ATCF.sdesignation=[basin snum_cha];

% process the run type
rtype=string(table2array(ATCF_data(:,5)));
runtype=rtype(1);
ATCF.runtype=rtype;
if strcmp(runtype,'OFCL') || strcmp(runtype,'BEST') || ...
   strcmp(runtype,'IBTr') || strcmp(runtype,'fort22') || ...
   strcmp(runtype,'MAPP')
else
   fprintf('Error in read_ATCF_fort22.m. Unrecogrnized runtype %s.\n',runtype)
end

% process date/time by summing run initiation time and offset time
% returned as a datetime array

runtime=num2str(table2array(ATCF_data(:,3)));
runtime_dt=datetime(runtime,'InputFormat','yyyyMMddHH');
runtime_str=string(runtime_dt,'yyyMMddHH');
offsettime_dt=hours(table2array(ATCF_data(:,6)));
offsettime_str=string(table2array(ATCF_data(:,6)));
runtimemin=table2array(ATCF_data(:,4));
for i=1:rows
    if isnan(runtimemin(i))       
        runtimemin(i)=0;
    end
    if runtimemin(i)<10
        runtimemin_cha(1)='0';
        runtimemin_cha(2)=num2str(runtimemin(i));
    else
        runtimemin_cha(1:2)=num2str(runtimemin(i));  
    end
runtimemin_str(i,1)=convertCharsToStrings(runtimemin_cha);
end
ttime_dt=runtime_dt+hours(runtimemin/60);
if strcmp(runtype,'OFCL')
    ttime_dt=ttime_dt+offsettime_dt;
end
ATCF.runtime_str=runtime_str;
ATCF.offsettime_str=offsettime_str;
ATCF.runtimemin_str=convertCharsToStrings(runtimemin_str);
ATCF.datetime=ttime_dt;

% read and pack TC eye location.  Strip off the final letter (N,S,E,W)
% Convert to degrees with W,S = -lon,lat.

lat1=table2array(ATCF_data(:,7));
lon1=table2array(ATCF_data(:,8)); 
for i=1:rows
    lattemp=cell2mat(lat1(i));
    lontemp=cell2mat(lon1(i));
    ATCF.lat(i)=str2double(lattemp(1:length(lattemp)-1))/10;
    ATCF.lon(i)=str2double(lontemp(1:length(lontemp)-1))/10;
    if lattemp(length(lattemp)) == 'S'
        ATCF.lat(i)=-ATCF.lat(i);
    end
    if lontemp(length(lontemp)) == 'W'
        ATCF.lon(i)=-ATCF.lon(i);
    end
end
ATCF.lon=ATCF.lon';
ATCF.lat=ATCF.lat';

% read and pack TC parameters.

ATCF.Vmax=table2array(ATCF_data(:,9));       
ATCF.Pmin=table2array(ATCF_data(:,10));
if double(char(table2array(ATCF_data(1,11)))) == 0
    ATCF.stype(1:rows,1)=' ';
else
    ATCF.stype=char(table2array(ATCF_data(:,11)));  %LO, TD, TS, HU, EX
end
isotach=table2array(ATCF_data(:,12));
if double(char(table2array(ATCF_data(1,13)))) == 0
    ATCF.wincode(1:rows,1)=' ';
else
    ATCF.wincode=char(table2array(ATCF_data(:,13)));  %AAA or NEQ
end
ATCF.R00=zeros(rows,4);
ATCF.R34=zeros(rows,4);
ATCF.R50=zeros(rows,4);
ATCF.R64=zeros(rows,4);
for i=1:rows
    if isotach(i) == 0
        ATCF.R00(i,1)=table2array(ATCF_data(i,14));       
        ATCF.R00(i,2)=table2array(ATCF_data(i,15));
        ATCF.R00(i,3)=table2array(ATCF_data(i,16));
        ATCF.R00(i,4)=table2array(ATCF_data(i,17));
    end    
    if isotach(i) == 34
        ATCF.R34(i,1)=table2array(ATCF_data(i,14));       
        ATCF.R34(i,2)=table2array(ATCF_data(i,15));
        ATCF.R34(i,3)=table2array(ATCF_data(i,16));
        ATCF.R34(i,4)=table2array(ATCF_data(i,17));
    end
    if isotach(i) == 50
        ATCF.R50(i,1)=table2array(ATCF_data(i,14));       
        ATCF.R50(i,2)=table2array(ATCF_data(i,15));
        ATCF.R50(i,3)=table2array(ATCF_data(i,16));
        ATCF.R50(i,4)=table2array(ATCF_data(i,17));
    end
    if isotach(i) == 64
        ATCF.R64(i,1)=table2array(ATCF_data(i,14));       
        ATCF.R64(i,2)=table2array(ATCF_data(i,15));
        ATCF.R64(i,3)=table2array(ATCF_data(i,16));
        ATCF.R64(i,4)=table2array(ATCF_data(i,17));
    end
end
ATCF.Pouter=table2array(ATCF_data(:,18));       
ATCF.Router=table2array(ATCF_data(:,19));       
ATCF.RMW=table2array(ATCF_data(:,20));         
ATCF.gust=table2array(ATCF_data(:,21));       %gusts kt  (c21)
ATCF.eyedia=table2array(ATCF_data(:,22));     %eye diam n mi  (c22)
if ft_ATCF || ft_ASWIP    % zero out cols 23-25 not used
    ATCF.dist2land=zeros(1,rows); 
    ATCF.envdir=zeros(1,rows);
    ATCF.envspd=zeros(1,rows);
end
if ft_GAHM2026    % in GAHM2026 fort22 but not in ATCF
    ATCF.dist2land=table2array(ATCF_data(:,23)); %distance to land (n mi)
    ATCF.envdir=table2array(ATCF_data(:,24)); %environment dir deg CW from N
    ATCF.envspd=table2array(ATCF_data(:,25)); %environment speed kt
end
ATCF.trandir=table2array(ATCF_data(:,26));       %translation dir deg CW from N
ATCF.transpd=table2array(ATCF_data(:,27));       %translation speed kt
ATCF.sname=char(table2array(ATCF_data(:,28)));   %storm name
if ft_ASWIP || ft_GAHM2026
    if ft_ASWIP
        iofst=0;
    else
        iofst=1;
    end    
    ATCF.timerec=table2array(ATCF_data(:,29));
    ATCF.numiso=table2array(ATCF_data(:,30));    
    ATCF.flag00=zeros(rows,4);    
    ATCF.flag34=zeros(rows,4);
    ATCF.flag50=zeros(rows,4);
    ATCF.flag64=zeros(rows,4);
    ATCF.flag_B=zeros(rows);
    ATCF.Rmax00=zeros(rows,4);    
    ATCF.Rmax34=zeros(rows,4);
    ATCF.Rmax50=zeros(rows,4);
    ATCF.Rmax64=zeros(rows,4);
    ATCF.B00=zeros(rows,1);    
    ATCF.B34=zeros(rows,1);
    ATCF.B50=zeros(rows,1);
    ATCF.B64=zeros(rows,1);
    ATCF.Bg00=zeros(rows,4);    
    ATCF.Bg34=zeros(rows,4);
    ATCF.Bg50=zeros(rows,4);
    ATCF.Bg64=zeros(rows,4);
    for i=1:rows
        if isotach(i) == 0
            if ft_GAHM2026
                ATCF.flag00(i,1)=table2array(ATCF_data(i,31));            
                ATCF.flag00(i,2)=table2array(ATCF_data(i,32));
                ATCF.flag00(i,3)=table2array(ATCF_data(i,33));
                ATCF.flag00(i,4)=table2array(ATCF_data(i,34));
                ATCF.flag_B(i)=table2array(ATCF_data(i,35));
            elseif ft_ASWIP    % overwite values in ASWIP file
                ATCF.numiso(i)=0;                
                ATCF.flag00(i,1:4)=2;
                ATCF.flag_B(i)=NaN;
            end
            ATCF.Rmax00(i,1)=table2array(ATCF_data(i,35+iofst));       
            ATCF.Rmax00(i,2)=table2array(ATCF_data(i,36+iofst));
            ATCF.Rmax00(i,3)=table2array(ATCF_data(i,37+iofst));
            ATCF.Rmax00(i,4)=table2array(ATCF_data(i,38+iofst));
            ATCF.B00(i,1)=table2array(ATCF_data(i,39+iofst));
            ATCF.Bg00(i,1)=table2array(ATCF_data(i,40+iofst));       
            ATCF.Bg00(i,2)=table2array(ATCF_data(i,41+iofst));
            ATCF.Bg00(i,3)=table2array(ATCF_data(i,42+iofst));
            ATCF.Bg00(i,4)=table2array(ATCF_data(i,43+iofst));      
        end
        if isotach(i) == 34
            ATCF.flag34(i,1)=table2array(ATCF_data(i,31));            
            ATCF.flag34(i,2)=table2array(ATCF_data(i,32));
            ATCF.flag34(i,3)=table2array(ATCF_data(i,33));
            ATCF.flag34(i,4)=table2array(ATCF_data(i,34));
            if ft_GAHM2026
                ATCF.flag_B(i)=table2array(ATCF_data(i,35));
            else
                ATCF.flag_B(i)=NaN;
            end
            ATCF.Rmax34(i,1)=table2array(ATCF_data(i,35+iofst));       
            ATCF.Rmax34(i,2)=table2array(ATCF_data(i,36+iofst));
            ATCF.Rmax34(i,3)=table2array(ATCF_data(i,37+iofst));
            ATCF.Rmax34(i,4)=table2array(ATCF_data(i,38+iofst));
            ATCF.B34(i)=table2array(ATCF_data(i,39+iofst));
            ATCF.Bg34(i,1)=table2array(ATCF_data(i,40+iofst));       
            ATCF.Bg34(i,2)=table2array(ATCF_data(i,41+iofst));
            ATCF.Bg34(i,3)=table2array(ATCF_data(i,42+iofst));
            ATCF.Bg34(i,4)=table2array(ATCF_data(i,43+iofst));      
        end
        if isotach(i) == 50
            ATCF.flag50(i,1)=table2array(ATCF_data(i,31));            
            ATCF.flag50(i,2)=table2array(ATCF_data(i,32));
            ATCF.flag50(i,3)=table2array(ATCF_data(i,33));
            ATCF.flag50(i,4)=table2array(ATCF_data(i,34));
            if ft_GAHM2026
                ATCF.flag_B(i)=table2array(ATCF_data(i,35));
            else
                ATCF.flag_B(i)=NaN;
            end
            ATCF.Rmax50(i,1)=table2array(ATCF_data(i,35+iofst));       
            ATCF.Rmax50(i,2)=table2array(ATCF_data(i,36+iofst));
            ATCF.Rmax50(i,3)=table2array(ATCF_data(i,37+iofst));
            ATCF.Rmax50(i,4)=table2array(ATCF_data(i,38+iofst));
            ATCF.B50(i)=table2array(ATCF_data(i,39+iofst));
            ATCF.Bg50(i,1)=table2array(ATCF_data(i,40+iofst));       
            ATCF.Bg50(i,2)=table2array(ATCF_data(i,41+iofst));
            ATCF.Bg50(i,3)=table2array(ATCF_data(i,42+iofst));
            ATCF.Bg50(i,4)=table2array(ATCF_data(i,43+iofst));
        end
        if isotach(i) == 64
            ATCF.flag64(i,1)=table2array(ATCF_data(i,31));            
            ATCF.flag64(i,2)=table2array(ATCF_data(i,32));
            ATCF.flag64(i,3)=table2array(ATCF_data(i,33));
            ATCF.flag64(i,4)=table2array(ATCF_data(i,34));            
            if ft_GAHM2026
                ATCF.flag_B(i)=table2array(ATCF_data(i,35));
            else
                ATCF.flag_B(i)=NaN;
            end
            ATCF.Rmax64(i,1)=table2array(ATCF_data(i,35+iofst));       
            ATCF.Rmax64(i,2)=table2array(ATCF_data(i,36+iofst));
            ATCF.Rmax64(i,3)=table2array(ATCF_data(i,37+iofst));
            ATCF.Rmax64(i,4)=table2array(ATCF_data(i,38+iofst));
            ATCF.B64(i)=table2array(ATCF_data(i,39+iofst));
            ATCF.Bg64(i,1)=table2array(ATCF_data(i,40+iofst));       
            ATCF.Bg64(i,2)=table2array(ATCF_data(i,41+iofst));
            ATCF.Bg64(i,3)=table2array(ATCF_data(i,42+iofst));
            ATCF.Bg64(i,4)=table2array(ATCF_data(i,43+iofst));
        end
    end
end

% process the VmaxVor_10_tbl and extra Rmax columns in GAHM2026.  Can skip 
% the Rmax 50, 64 kt isotachs since if these are present the data is the 
% same as for 34 kt

if ft_GAHM2026
    ATCF.VmaxVor_10_tbl00=zeros(rows);
    ATCF.SVorQuad_10_tbl00=zeros(rows,4);
    ATCF.SVorQuad_10_tbl34=zeros(rows,4);
    ATCF.SVorQuad_10_tbl50=zeros(rows,4);
    ATCF.SVorQuad_10_tbl64=zeros(rows,4);
    for i=1:rows
        if isotach(i) == 0
            ATCF.VmaxVor_10_tbl00(i,1)=table2array(ATCF_data(i,45));
            ATCF.SVorQuad_10_tbl00(i,1)=table2array(ATCF_data(i,46));       
            ATCF.SVorQuad_10_tbl00(i,2)=table2array(ATCF_data(i,47));
            ATCF.SVorQuad_10_tbl00(i,3)=table2array(ATCF_data(i,48));
            ATCF.SVorQuad_10_tbl00(i,4)=table2array(ATCF_data(i,49));          
        end
        if isotach(i) == 34
            ATCF.VmaxVor_10_tbl34(i,1)=table2array(ATCF_data(i,45));            
            ATCF.SVorQuad_10_tbl34(i,1)=table2array(ATCF_data(i,46));       
            ATCF.SVorQuad_10_tbl34(i,2)=table2array(ATCF_data(i,47));
            ATCF.SVorQuad_10_tbl34(i,3)=table2array(ATCF_data(i,48));
            ATCF.SVorQuad_10_tbl34(i,4)=table2array(ATCF_data(i,49));          
        end
        if isotach(i) == 50
            ATCF.VmaxVor_10_tbl50(i,1)=table2array(ATCF_data(i,45));            
            ATCF.SVorQuad_10_tbl50(i,1)=table2array(ATCF_data(i,46));       
            ATCF.SVorQuad_10_tbl50(i,2)=table2array(ATCF_data(i,47));
            ATCF.SVorQuad_10_tbl50(i,3)=table2array(ATCF_data(i,48));
            ATCF.SVorQuad_10_tbl50(i,4)=table2array(ATCF_data(i,49)); 
        end
        if isotach(i) == 64
            ATCF.VmaxVor_10_tbl64(i,1)=table2array(ATCF_data(i,45));            
            ATCF.SVorQuad_10_tbl64(i,1)=table2array(ATCF_data(i,46));       
            ATCF.SVorQuad_10_tbl64(i,2)=table2array(ATCF_data(i,47));
            ATCF.SVorQuad_10_tbl64(i,3)=table2array(ATCF_data(i,48));
            ATCF.SVorQuad_10_tbl64(i,4)=table2array(ATCF_data(i,49)); 
        end
        ATCF.RmaxQ(i,1)=table2array(ATCF_data(i,50));       
        ATCF.RmaxQ(i,2)=table2array(ATCF_data(i,51));
        ATCF.RmaxQ(i,3)=table2array(ATCF_data(i,52));
        ATCF.RmaxQ(i,4)=table2array(ATCF_data(i,53));          
        ATCF.Rmax_out(i,1)=table2array(ATCF_data(i,54));
        ATCF.Bg_out(i,1)=table2array(ATCF_data(i,55));
    end
end

% process the VmaxVor_1_tbl for ASWIP input. 

if ft_ASWIP
    ATCF.VmaxVor_1_tbl34=zeros(rows,4);
    ATCF.VmaxVor_1_tbl50=zeros(rows,4);
    ATCF.VmaxVor_1_tbl64=zeros(rows,4);
    for i=1:rows
        if isotach(i) == 0
            ATCF.VmaxVor_1_tbl00(i,1)=table2array(ATCF_data(i,44));       
            ATCF.VmaxVor_1_tbl00(i,2)=table2array(ATCF_data(i,45));
            ATCF.VmaxVor_1_tbl00(i,3)=table2array(ATCF_data(i,46));
            ATCF.VmaxVor_1_tbl00(i,4)=table2array(ATCF_data(i,47));          
        end        
        if isotach(i) == 34
            ATCF.VmaxVor_1_tbl34(i,1)=table2array(ATCF_data(i,44));       
            ATCF.VmaxVor_1_tbl34(i,2)=table2array(ATCF_data(i,45));
            ATCF.VmaxVor_1_tbl34(i,3)=table2array(ATCF_data(i,46));
            ATCF.VmaxVor_1_tbl34(i,4)=table2array(ATCF_data(i,47));          
        end
        if isotach(i) == 50
            ATCF.VmaxVor_1_tbl50(i,1)=table2array(ATCF_data(i,44));       
            ATCF.VmaxVor_1_tbl50(i,2)=table2array(ATCF_data(i,45));
            ATCF.VmaxVor_1_tbl50(i,3)=table2array(ATCF_data(i,46));
            ATCF.VmaxVor_1_tbl50(i,4)=table2array(ATCF_data(i,47));
        end
        if isotach(i) == 64
            ATCF.VmaxVor_1_tbl64(i,1)=table2array(ATCF_data(i,44));       
            ATCF.VmaxVor_1_tbl64(i,2)=table2array(ATCF_data(i,45));
            ATCF.VmaxVor_1_tbl64(i,3)=table2array(ATCF_data(i,46));
            ATCF.VmaxVor_1_tbl64(i,4)=table2array(ATCF_data(i,47));
        end
    end
end

%% create the ATCF2 one line per time snap format

newATCF_line=0;
ATCF_line=1;
while ATCF_line <= rows 
    newATCF_line=newATCF_line+1;
    ATCF2(newATCF_line).runtimemin_str=ATCF.runtimemin_str(ATCF_line);
    ATCF2(newATCF_line).offsettime_str=ATCF.offsettime_str(ATCF_line);
    ATCF2(newATCF_line).datetime=ATCF.datetime(ATCF_line);
    ATCF2(newATCF_line).runtime_str=ATCF.runtime_str(ATCF_line);
    ATCF2(newATCF_line).lat=ATCF.lat(ATCF_line);
    ATCF2(newATCF_line).lon=ATCF.lon(ATCF_line);
    ATCF2(newATCF_line).Vmax=ATCF.Vmax(ATCF_line);
    ATCF2(newATCF_line).Pmin=ATCF.Pmin(ATCF_line);    
    ATCF2(newATCF_line).Pouter=ATCF.Pouter(ATCF_line);
    ATCF2(newATCF_line).Router=ATCF.Router(ATCF_line);
    ATCF2(newATCF_line).RMW=ATCF.RMW(ATCF_line);
    ATCF2(newATCF_line).runtype_cha=ATCF.runtype(ATCF_line,:);    
    ATCF2(newATCF_line).basin_cha=ATCF.basin(ATCF_line,:);
    ATCF2(newATCF_line).snum_cha=ATCF.snum(ATCF_line,:);
    ATCF2(newATCF_line).sdesignation_cha=ATCF.sdesignation(ATCF_line,:);
    ATCF2(newATCF_line).stype_str=ATCF.stype(ATCF_line,:); 
    ATCF2(newATCF_line).wincode_cha=ATCF.wincode(ATCF_line,:);    
    ATCF2(newATCF_line).gust=ATCF.gust(ATCF_line);  
    ATCF2(newATCF_line).eyedia=ATCF.eyedia(ATCF_line);
    ATCF2(newATCF_line).dist2land=ATCF.dist2land(ATCF_line);
    ATCF2(newATCF_line).envdir=ATCF.envdir(ATCF_line);
    ATCF2(newATCF_line).envspd=ATCF.envspd(ATCF_line); 
    ATCF2(newATCF_line).trandir=ATCF.trandir(ATCF_line);
    ATCF2(newATCF_line).transpd=ATCF.transpd(ATCF_line);
    ATCF2(newATCF_line).sname_cha=ATCF.sname(ATCF_line,:);
    ATCF2(newATCF_line).R00=zeros(1,4);
    ATCF2(newATCF_line).R34=zeros(1,4);
    ATCF2(newATCF_line).R50=zeros(1,4);
    ATCF2(newATCF_line).R64=zeros(1,4);    
    if ft_ASWIP || ft_GAHM2026
        ATCF2(newATCF_line).timerec=ATCF.timerec(ATCF_line);
        ATCF2(newATCF_line).numiso=ATCF.numiso(ATCF_line);
        ATCF2(newATCF_line).flag00(:)=zeros(1,4);
        ATCF2(newATCF_line).flag34(:)=zeros(1,4);
        ATCF2(newATCF_line).flag50(:)=zeros(1,4);
        ATCF2(newATCF_line).flag64(:)=zeros(1,4);
        ATCF2(newATCF_line).flag_B=0;
        ATCF2(newATCF_line).Rmax00(:)=zeros(1,4);   
        ATCF2(newATCF_line).Rmax34(:)=zeros(1,4);        
        ATCF2(newATCF_line).Rmax50(:)=zeros(1,4);
        ATCF2(newATCF_line).Rmax64(:)=zeros(1,4);
        ATCF2(newATCF_line).B=0;        
        ATCF2(newATCF_line).Bg00(:)=zeros(1,4);        
        ATCF2(newATCF_line).Bg34(:)=zeros(1,4);
        ATCF2(newATCF_line).Bg50(:)=zeros(1,4);
        ATCF2(newATCF_line).Bg64(:)=zeros(1,4);
    end
    if ft_GAHM2026
        ATCF2(newATCF_line).SVorMax_10_tbl=0;  
        ATCF2(newATCF_line).SVorQuad_10_tbl00(:)=zeros(1,4);        
        ATCF2(newATCF_line).SVorQuad_10_tbl34(:)=zeros(1,4);
        ATCF2(newATCF_line).SVorQuad_10_tbl50(:)=zeros(1,4);
        ATCF2(newATCF_line).SVorQuad_10_tbl64(:)=zeros(1,4);        
    end
    if ft_ASWIP
        ATCF2(newATCF_line).B00=0;        
        ATCF2(newATCF_line).B34=0;
        ATCF2(newATCF_line).B50=0;
        ATCF2(newATCF_line).B64=0;        
        ATCF2(newATCF_line).VmaxVor_1_tbl00(:)=zeros(1,4);        
        ATCF2(newATCF_line).VmaxVor_1_tbl34(:)=zeros(1,4);
        ATCF2(newATCF_line).VmaxVor_1_tbl50(:)=zeros(1,4);
        ATCF2(newATCF_line).VmaxVor_1_tbl64(:)=zeros(1,4);  
    end
    while ATCF2(newATCF_line).datetime == ATCF.datetime(ATCF_line)
        if isotach(ATCF_line) == 0
            ATCF2(newATCF_line).R00(:)=ATCF.R00(ATCF_line,1:4);        
        elseif isotach(ATCF_line) == 34
            ATCF2(newATCF_line).R34(:)=ATCF.R34(ATCF_line,1:4);
        elseif isotach(ATCF_line) == 50
            ATCF2(newATCF_line).R50(:)=ATCF.R50(ATCF_line,1:4);
        elseif isotach(ATCF_line) == 64
            ATCF2(newATCF_line).R64(:)=ATCF.R64(ATCF_line,1:4);
        end
        if ft_ASWIP || ft_GAHM2026
            if isotach(ATCF_line) == 0
                ATCF2(newATCF_line).flag00(:)=ATCF.flag00(ATCF_line,1:4);                
                ATCF2(newATCF_line).Rmax00(:)=ATCF.Rmax00(ATCF_line,1:4);         
                ATCF2(newATCF_line).Bg00(:)=ATCF.Bg00(ATCF_line,1:4);
            elseif isotach(ATCF_line) == 34
                ATCF2(newATCF_line).flag34(:)=ATCF.flag34(ATCF_line,1:4);                
                ATCF2(newATCF_line).Rmax34(:)=ATCF.Rmax34(ATCF_line,1:4);          
                ATCF2(newATCF_line).Bg34(:)=ATCF.Bg34(ATCF_line,1:4);
            elseif isotach(ATCF_line) == 50                
                ATCF2(newATCF_line).flag50(:)=ATCF.flag50(ATCF_line,1:4);                
                ATCF2(newATCF_line).Rmax50(:)=ATCF.Rmax50(ATCF_line,1:4);
                ATCF2(newATCF_line).Bg50(:)=ATCF.Bg50(ATCF_line,1:4);          
            elseif isotach(ATCF_line) == 64
                ATCF2(newATCF_line).flag64(:)=ATCF.flag64(ATCF_line,1:4);                
                ATCF2(newATCF_line).Rmax64(:)=ATCF.Rmax64(ATCF_line,1:4);
                ATCF2(newATCF_line).Bg64(:)=ATCF.Bg64(ATCF_line,1:4);
            end  
            ATCF2(newATCF_line).flag_B=ATCF.flag_B(ATCF_line);
        end
        if ft_ASWIP  % load VmaxVor_1_tbl and compute RmaxQ and Rmax_out from fort.22 info
            if isotach(ATCF_line) == 0
                ATCF2(newATCF_line).B=ATCF.B00(ATCF_line);                  
                ATCF2(newATCF_line).B00=ATCF.B00(ATCF_line);                
                ATCF2(newATCF_line).VmaxVor_1_tbl00(:)=ATCF.VmaxVor_1_tbl00(ATCF_line,1:4);
            elseif isotach(ATCF_line) == 34
                ATCF2(newATCF_line).B=ATCF.B34(ATCF_line);                  
                ATCF2(newATCF_line).B34=ATCF.B34(ATCF_line);                
                ATCF2(newATCF_line).VmaxVor_1_tbl34(:)=ATCF.VmaxVor_1_tbl34(ATCF_line,1:4);
            elseif isotach(ATCF_line) == 50   
                ATCF2(newATCF_line).B=ATCF.B50(ATCF_line);                  
                ATCF2(newATCF_line).B50=ATCF.B50(ATCF_line);                
                ATCF2(newATCF_line).VmaxVor_1_tbl50(:)=ATCF.VmaxVor_1_tbl50(ATCF_line,1:4);              
            elseif isotach(ATCF_line) == 64
                ATCF2(newATCF_line).B=ATCF.B64(ATCF_line);                  
                ATCF2(newATCF_line).B64=ATCF.B64(ATCF_line);                
                ATCF2(newATCF_line).VmaxVor_1_tbl64(:)=ATCF.VmaxVor_1_tbl64(ATCF_line,1:4);
            end       
            ATCF2(newATCF_line).RmaxQ(:)=ATCF2(newATCF_line).Rmax34(:);
            for q=1:4
                if ATCF2(newATCF_line).Rmax64(q) ~=0
                    ATCF2(newATCF_line).RmaxQ(q)=ATCF2(newATCF_line).Rmax64(q);
                elseif ATCF2(newATCF_line).Rmax50(q) ~=0
                    ATCF2(newATCF_line).RmaxQ(q)=ATCF2(newATCF_line).Rmax50(q);
                end
            end          
            if newATCF_line == 1
                VTspeed_10_10=0;
            else
                delts=seconds(ATCF2(newATCF_line).datetime-ATCF2(newATCF_line-1).datetime);                
                VTspeed_10_10=distance('rh', ATCF2(newATCF_line-1).lat, ...
                    ATCF2(newATCF_line-1).lon, ATCF2(newATCF_line).lat, ...
                    ATCF2(newATCF_line).lon, earthRadiusInMeters)/delts; %translation speed from backward difference m/s
                VTspeed_10_10=VTspeed_10_10*1.944; % convert to knots
                ATCF2(newATCF_line).transpd=VTspeed_10_10;
            end
            if isnan(VTspeed_10_10) || VTspeed_10_10 == 0 
                VTspeed_10_10=0;
                VTdirection_10_10=0;
                VTuv_10_10=[0, 0];
                ATCF2(newATCF_line).Rmax_out=0;
                ATCF2(newATCF_line).transpd=VTspeed_10_10;                
            else
                VTdirection_10_10=(360-azimuth('rh',ATCF2(newATCF_line-1).lat, ...
                    ATCF2(newATCF_line-1).lon, ATCF2(newATCF_line).lat, ...
                    ATCF2(newATCF_line).lon))+90;  %translation direction ccw from E
                if VTdirection_10_10 > 360
                    VTdirection_10_10 = VTdirection_10_10-360;  % CCW from E
                end
                VTuv_10_10 = [cosd(VTdirection_10_10), sind(VTdirection_10_10)];
                [ATCF2(newATCF_line).Rmax_tot, Rmax_tot_angle]= ...
                    computeRmaxTot(ATCF2(newATCF_line).RmaxQ,VTuv_10_10); % compute single Rmax
                ATCF2(newATCF_line).Bg_tot=NaN;
            end
            if VTspeed_10_10==0
                ATCF2(newATCF_line).envdir=0;
            else
                ATCF2(newATCF_line).envdir=90-VTdirection_10_10;  % convert to CW from N
                if ATCF2(newATCF_line).envdir < 0
                    ATCF2(newATCF_line).envdir = ATCF2(newATCF_line).envdir+360;
                end
            end
            ATCF2(newATCF_line).envspd=1.5*VTspeed_10_10^0.63;  % as done in ADCIRC / ASWIP Schwerdt NOAAA TR NWS 23, 1979
            ATCF2(newATCF_line).trandir=ATCF2(newATCF_line).envdir;          
        end
        if ft_GAHM2026 % load VmaxVor_10_tbl and copy RmaxQ and Rmax_out from fort.22 info
            if isotach(ATCF_line) == 0
                ATCF2(newATCF_line).B=ATCF.B00(ATCF_line);                     
                ATCF2(newATCF_line).SVorMax_10_tbl=ATCF.VmaxVor_10_tbl00(ATCF_line,1);
                ATCF2(newATCF_line).SVorQuad_10_tbl00(:)=ATCF.SVorQuad_10_tbl00(ATCF_line,1:4);            
            elseif isotach(ATCF_line) == 34
                ATCF2(newATCF_line).B=ATCF.B34(ATCF_line);                     
                ATCF2(newATCF_line).SVorMax_10_tbl=ATCF.VmaxVor_10_tbl34(ATCF_line,1);                
                ATCF2(newATCF_line).SVorQuad_10_tbl34(:)=ATCF.SVorQuad_10_tbl34(ATCF_line,1:4);
            elseif isotach(ATCF_line) == 50         
                ATCF2(newATCF_line).B=ATCF.B50(ATCF_line);                
                ATCF2(newATCF_line).SVorMax_10_tbl=ATCF.VmaxVor_10_tbl50(ATCF_line,1);                
                ATCF2(newATCF_line).SVorQuad_10_tbl50(:)=ATCF.SVorQuad_10_tbl50(ATCF_line,1:4);              
            elseif isotach(ATCF_line) == 64
                ATCF2(newATCF_line).B=ATCF.B64(ATCF_line);                
                ATCF2(newATCF_line).SVorMax_10_tbl=ATCF.VmaxVor_10_tbl64(ATCF_line,1);                
                ATCF2(newATCF_line).SVorQuad_10_tbl64(:)=ATCF.SVorQuad_10_tbl64(ATCF_line,1:4);
            end 
            ATCF2(newATCF_line).RmaxQ(:)=ATCF.RmaxQ(ATCF_line,1:4);             
            ATCF2(newATCF_line).Rmax_tot=ATCF.Rmax_out(ATCF_line);  
            ATCF2(newATCF_line).Bg_tot=ATCF.Bg_out(ATCF_line);
        end
        ATCF_line=ATCF_line+1;
        if ATCF_line > rows  
            break
        end
    end    
end

end

