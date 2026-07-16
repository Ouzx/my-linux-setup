When I use my headphone to watch video on Youtube, I noticed that there is a lag between the audio and the video when i change the time of the video. It can easily fixed via changing the Latency offset in the Pavucontrol.

Find the output device in the gui, click advanced, and adjust the latency via testing;
For my soundcore Space One, I set the latency offset to -200ms.

You can also see the current Roundtrip latency via Zen's `about:support` page under `Media` section as `Roundtrip latency (standard deviation)`. You need to refresh the page to see the changes. With the current 200ms setting, the lag is around `56.52ms (11.87)`, and its not noticeable.
For my Nothing Ear 3a, I set the latency -200ms, and the result is around `45.02ms (7.90)`

Also if Pavucontrol is not changing the latency, you can restart the pc and try again easily.