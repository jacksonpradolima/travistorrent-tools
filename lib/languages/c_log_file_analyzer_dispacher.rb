load 'lib/languages/c_make_log_file_analyzer.rb'
load 'lib/languages/c_make_summary_log_file_analyzer.rb'
load 'lib/languages/c_default_log_file_analyzer.rb'

# A Mixin-dispatcher for C-based logs that decides what is the correct sub C analyzer by quickly browsing through
# the log contents. This has minimal overhead compared to directly calling the correct sub analyzer through lazy
# initializing the loaded file, and is far better than trying every existing sub-analyzer and seeing which one worked

module JavaLogFileAnalyzerDispatcher

  def init
    if @logFile.scan(/(make  check-TESTS)/m).size >= 1
      # if the project contains 1 or more make commands to test
      # we check if the log contains the test suite summary 
      if @logFile.scan(/(Testsuite summary for)/m).size >= 1
        # this kind of log contains an easy way to extract the log
        self.extend CMakeSummaryLogFileAnalyzer
      else
        # on the other hand, we do not know when the tests finished
        self.extend CMakeLogFileAnalyzer
    else
      self.extend CDefaultLogFileAnalyzer
    end

    init_deep
  end
end