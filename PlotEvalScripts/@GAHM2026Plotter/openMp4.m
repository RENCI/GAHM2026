function vw = openMp4(obj, filename)
% openMp4  Create and open a VideoWriter for MP4 output.

    vw = VideoWriter(filename, 'MPEG-4');
    vw.FrameRate = obj.Opts.anim.frameRate;
    vw.Quality   = 100;
    open(vw);

end
