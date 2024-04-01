--#if constants
--(when using replace_strings, engine constants are replaced directly so this file can be skipped)

alignments = {
  left = 1,
  horizontal_center = 2,
  center = 3,
  right = 4
}

--#else

-- dummy statement pretending we're returning a module
--  to avoid picotool failure on empty file with Travis
return nil

--(constants)
--#endif
