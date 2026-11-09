### Fixed
* Restored the CSV column headers - lost them a few versions back
* Timestamps are way more accurate now by using `os.time()` (I don't remember why I had to do acrobatics involving the time and framecount)
* Got rid of everything related to frame count and framerate
* Cleaned up unused variables
