% script to read in GAHM2026 produced Rmax values and plot comparisons
% for Yoyo's 13 storms
%
%                             RL 3/31/2025

echo off

Florence_BLF0p90=readtable('GAHM2026_Florence_bk2_fort22.dat');
Francine_BLF0p90=readtable('GAHM2026_Francine_bk2_fort22.dat');
Helene_BLF0p90  =readtable('GAHM2026_Helene_bk2_fort22.dat');
Ian_BLF0p90     =readtable('GAHM2026_Ian_bk2_fort22.dat');
Ida_BLF0p90     =readtable('GAHM2026_Ida_bk2_fort22.dat');
Idalia_BLF0p90  =readtable('GAHM2026_Idalia_bk2_fort22.dat');
Irma_BLF0p90    =readtable('GAHM2026_Irma_bk2_fort22.dat');
Isaias_BLF0p90  =readtable('GAHM2026_Isaias_bk2_fort22.dat');
Laura_BLF0p90   =readtable('GAHM2026_Laura_bk2_fort22.dat');
Maria_BLF0p90   =readtable('GAHM2026_Maria_bk2_fort22.dat');
Matthew_BLF0p90 =readtable('GAHM2026_Matthew_bk2_fort22.dat');
Michael_BLF0p90 =readtable('GAHM2026_Michael_bk2_fort22.dat');
Milton_BLF0p90  =readtable('GAHM2026_Milton_bk2_fort22.dat');

storm{1}=Florence_BLF0p90;
storm{2}=Francine_BLF0p90;
storm{3}=Helene_BLF0p90;
storm{4}=Ian_BLF0p90;
storm{5}=Ida_BLF0p90;
storm{6}=Idalia_BLF0p90;
storm{7}=Irma_BLF0p90;
storm{8}=Isaias_BLF0p90;
storm{9}=Laura_BLF0p90;
storm{10}=Maria_BLF0p90;
storm{11}=Matthew_BLF0p90;
storm{12}=Michael_BLF0p90;
storm{13}=Milton_BLF0p90;

for istorm=1:13
    i0(istorm)=0;
    i1(istorm)=0;
    i2(istorm)=0;
    i3(istorm)=0;
    stormlen(istorm)=length(storm{istorm}.Var30);
    for i=1:stormlen(istorm)
        if storm{istorm}.Var30(i) == 0
            i0(istorm)=i0(istorm)+1;
            Rmaxinp90_0kt(istorm,i0(istorm))=storm{istorm}.Var20(i);
            Rmaxcal90_0kt(istorm,i0(istorm))=storm{istorm}.Var52(i);
        end
        if storm{istorm}.Var30(i) == 1
            i1(istorm)=i1(istorm)+1;
            Rmaxinp90_34kt(istorm,i1(istorm))=storm{istorm}.Var20(i);
            Rmaxcal90_34kt(istorm,i1(istorm))=storm{istorm}.Var52(i);
        end
        if storm{istorm}.Var30(i) == 2
            i2(istorm)=i2(istorm)+1;
            Rmaxinp90_50kt(istorm,i2(istorm))=storm{istorm}.Var20(i);
            Rmaxcal90_50kt(istorm,i2(istorm))=storm{istorm}.Var52(i);
        end
        if storm{istorm}.Var30(i) == 3
            i3(istorm)=i3(istorm)+1;
            Rmaxinp90_64kt(istorm,i3(istorm))=storm{istorm}.Var20(i);
            Rmaxcal90_64kt(istorm,i3(istorm))=storm{istorm}.Var52(i);
        end
    end
end

