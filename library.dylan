module: dylan-user

define library bard
  use dylan;
  use common-dylan;
  use io;
end library;

define module bard
  use common-dylan, exclude: { format-to-string };
  use dylan-extensions;
  use simple-profiling;
  use format-out;
  use print;
end module;
