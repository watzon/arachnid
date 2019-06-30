module Arachnid
  class Cli < Clim
    abstract class Action

      abstract def run(opts, args) : Nil

    end
  end
end
