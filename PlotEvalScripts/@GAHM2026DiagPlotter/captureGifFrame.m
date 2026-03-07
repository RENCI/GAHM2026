function captureGifFrame(obj, fig, ip, istart, filename)
% captureGifFrame  Append the current figure as a GIF frame.

    frame = getframe(fig);
    im = frame2im(frame);
    [A, maps] = rgb2ind(im, 256);

    if ip == istart
        imwrite(A, maps, filename, 'gif', 'LoopCount', Inf, ...
            'DelayTime', 1/obj.Opts.anim.frameRate);
    else
        imwrite(A, maps, filename, 'gif', 'WriteMode', 'append', ...
            'DelayTime', 1/obj.Opts.anim.frameRate);
    end

end