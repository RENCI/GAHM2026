% Script to read in and parse IBTrACS format TC track files
% Data is sent back to calling program in the ATCF2 data structure which
% should match the structure that comes back from the script 
% read_ATCF_fort22.m
%
% The input data file must be in IBTrACS delimited text format and end in 
% .csv, .txt or .dat
% Because the IBTrACS file has many empty cells, particularly for earlier 
% years, Matlab can have difficulty reading it.  It is advisable to "seed" 
% columns 22 and 23 in the file by putting "" in each on the first line of 
% data in the file (e.g., using excell or a text editor) if they are 
% otherwise empty.  If they have values, there is no need to modify further.  
%
% time is returned in datetime formats
% eye location returned in deg lon,lat (S,W = - lon,lat)
% all other variables returned in original units, i.e., 
%     Wind speed in knots
%     Pressure in milibars
%     Disances in nautical miles
% isotach radii are organized by quadrants clockwise from NE, i.e., 
%                                             1:4 = NE, SE, SW, NW
%
% 
%                Rick Luettich  10/27/2024
%                           RL   7/ 8/2025 added ATCF2.numiso

function ATCF2=read_IBTrACS2(storm)

% read the IBTrACS file

IBTrACS_data=readtable(storm.file_name);

% find the storm in the file
sdesig_long=string([storm.designation storm.year]);
firstline=find(string(table2array(IBTrACS_data(:,19)))==sdesig_long,1,'first');
lastline=find(string(table2array(IBTrACS_data(:,19)))==sdesig_long,1,'last');
storm_rows=lastline-firstline+1;

% process date/time 
Adatetime=datetime(table2array(IBTrACS_data(firstline:lastline,7)));
month_num=month(Adatetime);
day_num=day(Adatetime);
hour_num=hour(Adatetime);

% load the ATCF2 data structure

for i=firstline:lastline
    j=i-firstline+1;
    ATCF2(j).runtimemin_str=string(minute(Adatetime(j)));
    ATCF2(j).offsettime_str="0";
    ATCF2(j).datetime=Adatetime(j);
    year_str=string(year(Adatetime(j)));
    if month_num(j) < 10
        month_str=strcat("0",string(month_num(j)));
    else
        month_str=string(month_num(j));
    end
    if day_num(j) < 10
        day_str=strcat("0",string(day_num(j)));
    else
        day_str=string(day_num(j));
    end
    if hour_num(j) < 10
        hour_str=strcat("0",string(hour_num(j)));
    else
        hour_str=string(hour_num(j));
    end
    ATCF2(j).runtime_str=strcat(year_str,month_str,day_str,hour_str);
    ATCF2(j).lat=str2double(string(table2array(IBTrACS_data(i,20))));
    ATCF2(j).lon=str2double(string(table2array(IBTrACS_data(i,21))));
    ATCF2(j).Vmax=str2double(string(table2array(IBTrACS_data(i,24))));       
    ATCF2(j).Pmin=str2double(string(table2array(IBTrACS_data(i,25))));
    ATCF2(j).Pouter=str2double(string(table2array(IBTrACS_data(i,39))));       
    ATCF2(j).Router=str2double(string(table2array(IBTrACS_data(i,40))));       
    ATCF2(j).RMW=str2double(string(table2array(IBTrACS_data(i,41))));         
    ATCF2(j).runtype_cha='IBTr';
    designation=char(string(table2array(IBTrACS_data(i,19))));
    ATCF2(j).basin_cha=designation(1:2);
    ATCF2(j).snum_cha=designation(3:4);
    ATCF2(j).sdesignation_cha=designation(1:4);
    ATCF2(j).stype_str=string(table2array(IBTrACS_data(i,23)));
    ATCF2(j).wincode_cha='   ';                       %wind code = AAA or NEQ?
    ATCF2(j).gust=str2double(string(table2array(IBTrACS_data(i,163))));   %gust (kt)
    ATCF2(j).eyedia=str2double(string(table2array(IBTrACS_data(i,42))));  %eye diam (n mi)
    ATCF2(j).dist2land=0.54*str2double(string(table2array(IBTrACS_data(i,15)))); % distance to land (n mi) = 0 @ landfall
    ATCF2(j).envdir=NaN;
    ATCF2(j).envspd=NaN;
    ATCF2(j).trandir=str2double(string(table2array(IBTrACS_data(i,174))));  %storm translation dir (deg CW from N)
    ATCF2(j).transpd=str2double(string(table2array(IBTrACS_data(i,173))));  %storm translation speed (kt)
    ATCF2(j).sname_cha=char(string(table2array(IBTrACS_data(i,6))));    
    R64iso=false;
    R50iso=false;
    R34iso=false;
    for q=1:4
        ATCF2(j).R34(q)=str2double(string(table2array(IBTrACS_data(i,26+q))));        
        if ~ismissing(ATCF2(j).R34(q)) && ATCF2(j).R34(q) ~=0 && ~isnan(ATCF2(j).R34(q))
            R34iso=true;
        end
        ATCF2(j).R50(q)=str2double(string(table2array(IBTrACS_data(i,30+q))));        
        if ~ismissing(ATCF2(j).R50(q)) && ATCF2(j).R50(q) ~=0 && ~isnan(ATCF2(j).R50(q))
            R50iso=true;
        end
        ATCF2(j).R64(q)=str2double(string(table2array(IBTrACS_data(i,34+q))));        
        if ~ismissing(ATCF2(j).R64(q)) && ATCF2(j).R64(q) ~=0 && ~isnan(ATCF2(j).R64(q))
            R64iso=true;
        end
    end
    ATCF2(j).numiso=0;    
    if R34iso
        ATCF2(j).numiso=ATCF2(j).numiso+1;
    end
    if R50iso
        ATCF2(j).numiso=ATCF2(j).numiso+1;
    end 
    if R64iso
        ATCF2(j).numiso=ATCF2(j).numiso+1;
    end    
end
