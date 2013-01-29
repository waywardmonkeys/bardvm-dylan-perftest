module: dylan-user

define library bard
  use common-dylan;
  use io;
end library;

define module bard
  use common-dylan, exclude: { format-to-string };
  use format-out;
end module;
