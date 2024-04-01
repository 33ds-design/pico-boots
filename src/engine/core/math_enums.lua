--#if constants
--(when using replace_strings, engine constants are replaced directly so this file can be skipped)

directions = {
  left = 0,
  up = 1,
  right = 2,
  down = 3
}

horizontal_dirs = {
  left = 1,
  right = 2
}

vertical_dirs = {
  up = 1,
  down = 2
}

--#else

-- dummy statement pretending we're returning a module
--  to avoid picotool failure on empty file with Travis
return nil

--(constants)
--#endif
