%script to compare GAHM2026 and ASWIP quantities
%
%            Rick Luettich 5/21/2025

function GAHM2026_ASWIP_compare(GAHM2026_BLF0p75,GAHM2026_BLF0p9,ASWIP,TCname_yr)

isync=0;
for i=1:length(GAHM2026_BLF0p9)
    for j=1:length(ASWIP)
        if ASWIP(j).datetime == GAHM2026_BLF0p9(i).datetime
            isync=isync+1;
            GAHM2026sync(isync)=i;
            ASWIPsync(isync)=j;
        end
    end
end

for i=1:isync
    RMW34_GAHM2026_BLF0p75(i,1:4)=GAHM2026_BLF0p75(GAHM2026sync(i)).Rmax34(1:4);
    RMW34_GAHM2026_BLF0p9(i,1:4)=GAHM2026_BLF0p9(GAHM2026sync(i)).Rmax34(1:4);    
    RMW34_ASWIP(i,1:4)=ASWIP(ASWIPsync(i)).Rmax34(1:4); 
    RMW50_GAHM2026_BLF0p75(i,1:4)=GAHM2026_BLF0p75(GAHM2026sync(i)).Rmax50(1:4);
    RMW50_GAHM2026_BLF0p9(i,1:4)=GAHM2026_BLF0p9(GAHM2026sync(i)).Rmax50(1:4);
    RMW50_ASWIP(i,1:4)=ASWIP(ASWIPsync(i)).Rmax50(1:4); 
    RMW64_GAHM2026_BLF0p75(i,1:4)=GAHM2026_BLF0p75(GAHM2026sync(i)).Rmax64(1:4);    
    RMW64_GAHM2026_BLF0p9(i,1:4)=GAHM2026_BLF0p9(GAHM2026sync(i)).Rmax64(1:4);
    RMW64_ASWIP(i,1:4)=ASWIP(ASWIPsync(i)).Rmax64(1:4);   
    RMW_GAHM2026_BLF0p75(i)=GAHM2026_BLF0p75(GAHM2026sync(i)).Rmax_out;
    if GAHM2026_BLF0p75(GAHM2026sync(i)).numiso == 0
        RMW_GAHM2026_BLF0p75(i)=NaN;
    end
    RMW_GAHM2026_BLF0p9(i)=GAHM2026_BLF0p9(GAHM2026sync(i)).Rmax_out;
    if GAHM2026_BLF0p9(GAHM2026sync(i)).numiso == 0
        RMW_GAHM2026_BLF0p9(i)=NaN;
    end  
    RMW_ASWIP(i)=ASWIP(ASWIPsync(i)).Rmax_out;
    if ASWIP(ASWIPsync(i)).numiso == 0
        RMW_ASWIP(i)=NaN;
    end    
    RMW_NHC(i)=ASWIP(ASWIPsync(i)).RMW;     
    Bg34_GAHM2026_BLF0p75(i,1:4)=GAHM2026_BLF0p75(GAHM2026sync(i)).Bg34(1:4);
    Bg34_GAHM2026_BLF0p9(i,1:4)=GAHM2026_BLF0p9(GAHM2026sync(i)).Bg34(1:4);    
    Bg34_ASWIP(i,1:4)=ASWIP(ASWIPsync(i)).Bg34(1:4);
    B34(i,1:4)=ASWIP(ASWIPsync(i)).B34;    
    Bg50_GAHM2026_BLF0p75(i,1:4)=GAHM2026_BLF0p75(GAHM2026sync(i)).Bg50(1:4);
    Bg50_GAHM2026_BLF0p9(i,1:4)=GAHM2026_BLF0p9(GAHM2026sync(i)).Bg50(1:4);
    Bg50_ASWIP(i,1:4)=ASWIP(ASWIPsync(i)).Bg50(1:4); 
    B50(i,1:4)=ASWIP(ASWIPsync(i)).B50;    
    Bg64_GAHM2026_BLF0p75(i,1:4)=GAHM2026_BLF0p75(GAHM2026sync(i)).Bg64(1:4);    
    Bg64_GAHM2026_BLF0p9(i,1:4)=GAHM2026_BLF0p9(GAHM2026sync(i)).Bg64(1:4);
    Bg64_ASWIP(i,1:4)=ASWIP(ASWIPsync(i)).Bg64(1:4);   
    B64(i,1:4)=ASWIP(ASWIPsync(i)).B64;   

    RMW34_GAHM2026_BLF0p75(i,find(RMW34_GAHM2026_BLF0p75(i,:)==0))=NaN;
    RMW34_GAHM2026_BLF0p9(i,find(RMW34_GAHM2026_BLF0p9(i,:)==0))=NaN;
    RMW34_ASWIP(i,find(RMW34_ASWIP(i,:)==0))=NaN;
    RMW50_GAHM2026_BLF0p75(i,find(RMW50_GAHM2026_BLF0p75(i,:)==0))=NaN;
    RMW50_GAHM2026_BLF0p9(i,find(RMW50_GAHM2026_BLF0p9(i,:)==0))=NaN;
    RMW50_ASWIP(i,find(RMW50_ASWIP(i,:)==0))=NaN;
    RMW64_GAHM2026_BLF0p75(i,find(RMW64_GAHM2026_BLF0p75(i,:)==0))=NaN;
    RMW64_GAHM2026_BLF0p9(i,find(RMW64_GAHM2026_BLF0p9(i,:)==0))=NaN;
    RMW64_ASWIP(i,find(RMW64_ASWIP(i,:)==0))=NaN;
end
for q=1:4
    RMW34_GAHM2026_BLF0p75(find(RMW34_GAHM2026_BLF0p75(:,q)==0),q)=NaN;
    RMW34_GAHM2026_BLF0p9(find(RMW34_GAHM2026_BLF0p9(:,q)==0),q)=NaN;
    RMW34_ASWIP(find(RMW34_ASWIP(:,q)==0),q)=NaN;
    RMW50_GAHM2026_BLF0p75(find(RMW50_GAHM2026_BLF0p75(:,q)==0),q)=NaN;
    RMW50_GAHM2026_BLF0p9(find(RMW50_GAHM2026_BLF0p9(:,q)==0),q)=NaN;
    RMW50_ASWIP(find(RMW50_ASWIP(:,q)==0),q)=NaN;
    RMW64_GAHM2026_BLF0p75(find(RMW64_GAHM2026_BLF0p75(:,q)==0),q)=NaN;
    RMW64_GAHM2026_BLF0p9(find(RMW64_GAHM2026_BLF0p9(:,q)==0),q)=NaN;
    RMW64_ASWIP(find(RMW64_ASWIP(:,q)==0),q)=NaN;
end

figure (1)
plot(RMW34_GAHM2026_BLF0p75(:,4),RMW34_ASWIP(:,4),'R.')
hold on
plot(RMW34_GAHM2026_BLF0p75(:,3),RMW34_ASWIP(:,3),'G.')
plot(RMW34_GAHM2026_BLF0p75(:,2),RMW34_ASWIP(:,2),'B.')
plot(RMW34_GAHM2026_BLF0p75(:,1),RMW34_ASWIP(:,1),'K.')
lim=max(max(max(RMW34_GAHM2026_BLF0p75,RMW34_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 34kt isotach'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax GAHM2026 BLF=0.75 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (2)
plot(RMW50_GAHM2026_BLF0p75(:,4),RMW50_ASWIP(:,4),'R.')
hold on
plot(RMW50_GAHM2026_BLF0p75(:,3),RMW50_ASWIP(:,3),'G.')
plot(RMW50_GAHM2026_BLF0p75(:,2),RMW50_ASWIP(:,2),'B.')
plot(RMW50_GAHM2026_BLF0p75(:,1),RMW50_ASWIP(:,1),'K.')
lim=max(max(max(RMW50_GAHM2026_BLF0p75,RMW50_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 50kt isotach'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax GAHM2026 BLF=0.75 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (3)
plot(RMW64_GAHM2026_BLF0p75(:,4),RMW64_ASWIP(:,4),'R.')
hold on
plot(RMW64_GAHM2026_BLF0p75(:,3),RMW64_ASWIP(:,3),'G.')
plot(RMW64_GAHM2026_BLF0p75(:,2),RMW64_ASWIP(:,2),'B.')
plot(RMW64_GAHM2026_BLF0p75(:,1),RMW64_ASWIP(:,1),'K.')
lim=max(max(max(RMW64_GAHM2026_BLF0p75,RMW64_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 64kt isotach'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax GAHM2026 BLF=0.75 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (4)
plot(RMW34_GAHM2026_BLF0p9(:,4),RMW34_ASWIP(:,4),'R.')
hold on
plot(RMW34_GAHM2026_BLF0p9(:,3),RMW34_ASWIP(:,3),'G.')
plot(RMW34_GAHM2026_BLF0p9(:,2),RMW34_ASWIP(:,2),'B.')
plot(RMW34_GAHM2026_BLF0p9(:,1),RMW34_ASWIP(:,1),'K.')
lim=max(max(max(RMW34_GAHM2026_BLF0p9,RMW34_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 34kt isotach'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax GAHM2026 BLF=0.90 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (5)
plot(RMW50_GAHM2026_BLF0p9(:,4),RMW50_ASWIP(:,4),'R.')
hold on
plot(RMW50_GAHM2026_BLF0p9(:,3),RMW50_ASWIP(:,3),'G.')
plot(RMW50_GAHM2026_BLF0p9(:,2),RMW50_ASWIP(:,2),'B.')
plot(RMW50_GAHM2026_BLF0p9(:,1),RMW50_ASWIP(:,1),'K.')
lim=max(max(max(RMW50_GAHM2026_BLF0p9,RMW50_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 50kt isotach'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax GAHM2026 BLF=0.9 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (6)
plot(RMW64_GAHM2026_BLF0p9(:,4),RMW64_ASWIP(:,4),'R.')
hold on
plot(RMW64_GAHM2026_BLF0p9(:,3),RMW64_ASWIP(:,3),'G.')
plot(RMW64_GAHM2026_BLF0p9(:,2),RMW64_ASWIP(:,2),'B.')
plot(RMW64_GAHM2026_BLF0p9(:,1),RMW64_ASWIP(:,1),'K.')
lim=max(max(max(RMW64_GAHM2026_BLF0p9,RMW64_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 64kt isotach'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax GAHM2026 BLF=0.90 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (7)
plot(RMW34_GAHM2026_BLF0p75(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW34_GAHM2026_BLF0p75(:,3),RMW_NHC(:),'G.')
plot(RMW34_GAHM2026_BLF0p75(:,2),RMW_NHC(:),'B.')
plot(RMW34_GAHM2026_BLF0p75(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW34_GAHM2026_BLF0p75)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 34kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax GAHM2026 BLF=0.75 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (8)
plot(RMW50_GAHM2026_BLF0p75(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW50_GAHM2026_BLF0p75(:,3),RMW_NHC(:),'G.')
plot(RMW50_GAHM2026_BLF0p75(:,2),RMW_NHC(:),'B.')
plot(RMW50_GAHM2026_BLF0p75(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW50_GAHM2026_BLF0p75)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 50kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax GAHM2026 BLF=0.75 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (9)
plot(RMW64_GAHM2026_BLF0p75(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW64_GAHM2026_BLF0p75(:,3),RMW_NHC(:),'G.')
plot(RMW64_GAHM2026_BLF0p75(:,2),RMW_NHC(:),'B.')
plot(RMW64_GAHM2026_BLF0p75(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW64_GAHM2026_BLF0p75)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 64kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax GAHM2026 BLF=0.75 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (10)
plot(RMW34_GAHM2026_BLF0p9(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW34_GAHM2026_BLF0p9(:,3),RMW_NHC(:),'G.')
plot(RMW34_GAHM2026_BLF0p9(:,2),RMW_NHC(:),'B.')
plot(RMW34_GAHM2026_BLF0p9(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW34_GAHM2026_BLF0p9)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 34kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax GAHM2026 BLF=0.90 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (11)
plot(RMW50_GAHM2026_BLF0p9(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW50_GAHM2026_BLF0p9(:,3),RMW_NHC(:),'G.')
plot(RMW50_GAHM2026_BLF0p9(:,2),RMW_NHC(:),'B.')
plot(RMW50_GAHM2026_BLF0p9(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW50_GAHM2026_BLF0p9)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 50kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax GAHM2026 BLF=0.90 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (12)
plot(RMW64_GAHM2026_BLF0p9(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW64_GAHM2026_BLF0p9(:,3),RMW_NHC(:),'G.')
plot(RMW64_GAHM2026_BLF0p9(:,2),RMW_NHC(:),'B.')
plot(RMW64_GAHM2026_BLF0p9(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW64_GAHM2026_BLF0p9)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 64kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax GAHM2026 BLF=0.90 (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (13)
plot(RMW34_ASWIP(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW34_ASWIP(:,3),RMW_NHC(:),'G.')
plot(RMW34_ASWIP(:,2),RMW_NHC(:),'B.')
plot(RMW34_ASWIP(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW34_ASWIP)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 34kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax ASWIP (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (14)
plot(RMW50_ASWIP(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW50_ASWIP(:,3),RMW_NHC(:),'G.')
plot(RMW50_ASWIP(:,2),RMW_NHC(:),'B.')
plot(RMW50_ASWIP(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW50_ASWIP)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 50kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax ASWIP (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (15)
plot(RMW64_ASWIP(:,4),RMW_NHC(:),'R.')
hold on
plot(RMW64_ASWIP(:,3),RMW_NHC(:),'G.')
plot(RMW64_ASWIP(:,2),RMW_NHC(:),'B.')
plot(RMW64_ASWIP(:,1),RMW_NHC(:),'K.')
lim=max(max(max(RMW64_ASWIP)), max(RMW_NHC));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison for 64kt isotach'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax ASWIP (nm)')
legend('NW Quadrant','SW Quadrant','SE Quadrant','NE Quadrant',' 1:1','Location','southeast')
axis([0 lim 0 lim])
hold off

figure (16)
plot(RMW_GAHM2026_BLF0p75(:),RMW_NHC(:),'B.')
hold on
plot(RMW_GAHM2026_BLF0p9(:),RMW_NHC(:),'G.')
plot(RMW_ASWIP(:),RMW_NHC(:),'R.')
lim=max([max(RMW_GAHM2026_BLF0p75), max(RMW_GAHM2026_BLF0p9), max(RMW_ASWIP), max(RMW_NHC)]);
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison'])
ylabel('Rmax NHC (nm)')
xlabel('Rmax computed (nm)')
legend('BLF=0.75','BLF=0.90','ASWIP',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (17)
plot(RMW_GAHM2026_BLF0p75(:),RMW_ASWIP(:),'B.')
hold on
plot(RMW_GAHM2026_BLF0p9(:),RMW_ASWIP(:),'G.')
lim=max([max(RMW_GAHM2026_BLF0p75), max(RMW_GAHM2026_BLF0p9), max(RMW_ASWIP)]);
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Rmax Comparison'])
ylabel('Rmax ASWIP (nm)')
xlabel('Rmax computed (nm)')
legend('BLF=0.75','BLF=0.90',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

skip=true;
if ~skip
figure (21)
plot(Bg34_GAHM2026_BLF0p75(:,1),Bg34_ASWIP(:,1),'K.')
hold on
plot(Bg34_GAHM2026_BLF0p75(:,2),Bg34_ASWIP(:,2),'B.')
plot(Bg34_GAHM2026_BLF0p75(:,3),Bg34_ASWIP(:,3),'G.')
plot(Bg34_GAHM2026_BLF0p75(:,4),Bg34_ASWIP(:,4),'R.')
lim=max(max(max(Bg34_GAHM2026_BLF0p75,Bg34_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 34kt isotach'])
ylabel('Bg ASWIP')
xlabel('Bg GAHM2026 BLF=0.75')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (22)
plot(Bg50_GAHM2026_BLF0p75(:,1),Bg50_ASWIP(:,1),'K.')
hold on
plot(Bg50_GAHM2026_BLF0p75(:,2),Bg50_ASWIP(:,2),'B.')
plot(Bg50_GAHM2026_BLF0p75(:,3),Bg50_ASWIP(:,3),'G.')
plot(Bg50_GAHM2026_BLF0p75(:,4),Bg50_ASWIP(:,4),'R.')
lim=max(max(max(Bg50_GAHM2026_BLF0p75,Bg50_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 50kt isotach'])
ylabel('Bg ASWIP')
xlabel('Bg GAHM2026 BLF=0.75')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (23)
plot(Bg64_GAHM2026_BLF0p75(:,1),Bg64_ASWIP(:,1),'K.')
hold on
plot(Bg64_GAHM2026_BLF0p75(:,2),Bg64_ASWIP(:,2),'B.')
plot(Bg64_GAHM2026_BLF0p75(:,3),Bg64_ASWIP(:,3),'G.')
plot(Bg64_GAHM2026_BLF0p75(:,4),Bg64_ASWIP(:,4),'R.')
lim=max(max(max(Bg64_GAHM2026_BLF0p75,Bg64_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 64kt isotach'])
ylabel('Bg ASWIP')
xlabel('Bg GAHM2026 BLF=0.75')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (24)
plot(Bg34_GAHM2026_BLF0p9(:,1),Bg34_ASWIP(:,1),'K.')
hold on
plot(Bg34_GAHM2026_BLF0p9(:,2),Bg34_ASWIP(:,2),'B.')
plot(Bg34_GAHM2026_BLF0p9(:,3),Bg34_ASWIP(:,3),'G.')
plot(Bg34_GAHM2026_BLF0p9(:,4),Bg34_ASWIP(:,4),'R.')
lim=max(max(max(Bg34_GAHM2026_BLF0p9,Bg34_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 34kt isotach'])
ylabel('Bg ASWIP')
xlabel('Bg GAHM2026 BLF=0.90')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (25)
plot(Bg50_GAHM2026_BLF0p9(:,1),Bg50_ASWIP(:,1),'K.')
hold on
plot(Bg50_GAHM2026_BLF0p9(:,2),Bg50_ASWIP(:,2),'B.')
plot(Bg50_GAHM2026_BLF0p9(:,3),Bg50_ASWIP(:,3),'G.')
plot(Bg50_GAHM2026_BLF0p9(:,4),Bg50_ASWIP(:,4),'R.')
lim=max(max(max(Bg50_GAHM2026_BLF0p9,Bg50_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 50kt isotach'])
ylabel('Bg ASWIP')
xlabel('Bg GAHM2026 BLF=0.90')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (26)
plot(Bg64_GAHM2026_BLF0p9(:,1),Bg64_ASWIP(:,1),'K.')
hold on
plot(Bg64_GAHM2026_BLF0p9(:,2),Bg64_ASWIP(:,2),'B.')
plot(Bg64_GAHM2026_BLF0p9(:,3),Bg64_ASWIP(:,3),'G.')
plot(Bg64_GAHM2026_BLF0p9(:,4),Bg64_ASWIP(:,4),'R.')
lim=max(max(max(Bg64_GAHM2026_BLF0p9,Bg64_ASWIP)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 64kt isotach'])
ylabel('Bg ASWIP')
xlabel('Bg GAHM2026 BLF=0.90')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (27)
plot(Bg34_GAHM2026_BLF0p75(:,1),B34(:,1),'K.')
hold on
plot(Bg34_GAHM2026_BLF0p75(:,2),B34(:,2),'B.')
plot(Bg34_GAHM2026_BLF0p75(:,3),B34(:,3),'G.')
plot(Bg34_GAHM2026_BLF0p75(:,4),B34(:,4),'R.')
lim=max(max(max(Bg34_GAHM2026_BLF0p75,B34)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 34kt isotach'])
ylabel('B')
xlabel('Bg GAHM2026 BLF=0.75')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (28)
plot(Bg50_GAHM2026_BLF0p75(:,1),B50(:,1),'K.')
hold on
plot(Bg50_GAHM2026_BLF0p75(:,2),B50(:,2),'B.')
plot(Bg50_GAHM2026_BLF0p75(:,3),B50(:,3),'G.')
plot(Bg50_GAHM2026_BLF0p75(:,4),B50(:,4),'R.')
lim=max(max(max(Bg50_GAHM2026_BLF0p75,B50)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 50kt isotach'])
ylabel('B')
xlabel('Bg GAHM2026 BLF=0.75')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (29)
plot(Bg64_GAHM2026_BLF0p75(:,1),B64(:,1),'K.')
hold on
plot(Bg64_GAHM2026_BLF0p75(:,2),B64(:,2),'B.')
plot(Bg64_GAHM2026_BLF0p75(:,3),B64(:,3),'G.')
plot(Bg64_GAHM2026_BLF0p75(:,4),B64(:,4),'R.')
lim=max(max(max(Bg64_GAHM2026_BLF0p75,B64)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 64kt isotach'])
ylabel('B')
xlabel('Bg GAHM2026 BLF=0.75')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (30)
plot(Bg34_GAHM2026_BLF0p9(:,1),B34(:,1),'K.')
hold on
plot(Bg34_GAHM2026_BLF0p9(:,2),B34(:,2),'B.')
plot(Bg34_GAHM2026_BLF0p9(:,3),B34(:,3),'G.')
plot(Bg34_GAHM2026_BLF0p9(:,4),B34(:,4),'R.')
lim=max(max(max(Bg34_GAHM2026_BLF0p9,B34)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 34kt isotach'])
ylabel('B')
xlabel('Bg GAHM2026 BLF=0.90')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (31)
plot(Bg50_GAHM2026_BLF0p9(:,1),B50(:,1),'K.')
hold on
plot(Bg50_GAHM2026_BLF0p9(:,2),B50(:,2),'B.')
plot(Bg50_GAHM2026_BLF0p9(:,3),B50(:,3),'G.')
plot(Bg50_GAHM2026_BLF0p9(:,4),B50(:,4),'R.')
lim=max(max(max(Bg50_GAHM2026_BLF0p9,B50)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 50kt isotach'])
ylabel('B')
xlabel('Bg GAHM2026 BLF=0.90')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (32)
plot(Bg64_GAHM2026_BLF0p9(:,1),B64(:,1),'K.')
hold on
plot(Bg64_GAHM2026_BLF0p9(:,2),B64(:,2),'B.')
plot(Bg64_GAHM2026_BLF0p9(:,3),B64(:,3),'G.')
plot(Bg64_GAHM2026_BLF0p9(:,4),B64(:,4),'R.')
lim=max(max(max(Bg64_GAHM2026_BLF0p9,B64)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 64kt isotach'])
ylabel('B')
xlabel('Bg GAHM2026 BLF=0.90')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (33)
plot(Bg34_ASWIP(:,1),B34(:,1),'K.')
hold on
plot(Bg34_ASWIP(:,2),B34(:,2),'B.')
plot(Bg34_ASWIP(:,3),B34(:,3),'G.')
plot(Bg34_ASWIP(:,4),B34(:,4),'R.')
lim=max(max(max(Bg34_ASWIP,B34)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 34kt isotach'])
ylabel('B')
xlabel('Bg ASWIP')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (34)
plot(Bg50_ASWIP(:,1),B50(:,1),'K.')
hold on
plot(Bg50_ASWIP(:,2),B50(:,2),'B.')
plot(Bg50_ASWIP(:,3),B50(:,3),'G.')
plot(Bg50_ASWIP(:,4),B50(:,4),'R.')
lim=max(max(max(Bg50_ASWIP,B50)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 50kt isotach'])
ylabel('B')
xlabel('Bg ASWIP')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

figure (35)
plot(Bg64_ASWIP(:,1),B64(:,1),'K.')
hold on
plot(Bg64_ASWIP(:,2),B64(:,2),'B.')
plot(Bg64_ASWIP(:,3),B64(:,3),'G.')
plot(Bg64_ASWIP(:,4),B64(:,4),'R.')
lim=max(max(max(Bg64_ASWIP,B64)));
plot([0 lim],[0 lim],'k--')
title(['Hurricane ',TCname_yr,'  Bg Comparison for 64kt isotach'])
ylabel('B')
xlabel('Bg ASWIP')
legend('NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant',' 1:1','Location','southeast');
axis([0 lim 0 lim])
hold off

end
