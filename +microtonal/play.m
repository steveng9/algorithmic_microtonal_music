

function play(name, audio_buffer)
    sound(audio_buffer, 44100);
    % % Save and play 
    audiowrite("audio_files/" + name + '.wav', audio_buffer, 44100);
    % sound(audio_buffer, 44100);

    [y, Fs] = audioread("audio_files/" + name + '.wav');
    player = audioplayer(y, Fs);
    play(player);
    while isplaying(player)
        pause(0.1);
    end
    disp('Audio playback finished.');

end