#  PBRecPlayer (Swift)

This program provides an example (on Apple's iOS) for how to get audio data from the microphone and reroute it to be heard through the speaker using Audio Unit. It's basically an skeleton of a audio calling app. It records audio, puts the recorder PCM data into TPCircularBuffer. Then it pulls that data, encode it to G729, decode it from G729 and again puts that into another TPCircularBuffer. And at last the player callback pulls that PCM data and plays through.  This will work on iOS 6 and higher.  

This is based on:  
  - http://atastypixel.com/blog/using-remoteio-audio-unit/ 
  - https://github.com/michaeltyson/TPCircularBuffer


If you don't know anything about digital audio or the core audio framework, I advice you read Apple's "Core Audio overview" to get some idea of what you're doing. Last located at:

  - http://developer.apple.com/library/ios/#documentation/MusicAudio/Conceptual/CoreAudioOverview/Introduction/Introduction.html




N.B. It's still under development. Any contribution will be highly appreciated. Feel free to contribute and contact.
    An Objective-C version is available at this link:  https://github.com/partho-maple/PBRecPlayer_Obj-C/
