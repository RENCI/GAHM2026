function cm=burd(m)

if nargin < 1
    f = get(groot,'CurrentFigure');
    if isempty(f)
        m = size(get(groot,'DefaultFigureColormap'),1);
    else
        m = size(f.Colormap,1);
    end
end

trgb=[
          0.0      0.01953      0.18750      0.37891
          0.1      0.12891      0.39844      0.67188
          0.2      0.26172      0.57422      0.76172
          0.3      0.57031      0.76953      0.86719
          0.4      0.81641      0.89453      0.93750
          0.5      0.96484      0.96484      0.96484
          0.6      0.98828      0.85547      0.77734
          0.7      0.95312      0.64453      0.50781
          0.8      0.83594      0.37500      0.30078
          0.9      0.69531      0.09375      0.16797
            1      0.40234      0.00000      0.12109
           ];

% interpolate
tn=(0:m-1)/(m-1);
tn=tn(:);

cm(:,1)=interp1(trgb(:,1),trgb(:,2),tn);
cm(:,2)=interp1(trgb(:,1),trgb(:,3),tn);
cm(:,3)=interp1(trgb(:,1),trgb(:,4),tn);

cm(cm<0)=0;
