# A Mixin for the analysis of C build files. 
# The tests are executed by the command 'make  check-TESTS' and finish when 'Testsuite summary for' information appear

module CMakeSummaryLogFileAnalyzer
  attr_reader :tests_failed, :test_duration

  def init_deep    
    @tests_failed_lines = Array.new
    @tests_failed = Array.new
    @tests_failed_num = Array.new
    @tests_runed = Array.new
    @tests_runed_num = Array.new
    @tests_runed_duration = Array.new
    @analyzer = 'cmakesummary'
  end

  def custom_analyze
    extract_tests
    analyze_tests
  end

  def extract_tests
    test_section_started = false
    
    @folds[@OUT_OF_FOLD].content.each do |line|

      if !(line =~ /make  check-TESTS/).nil?
        test_section_started = true        
      elsif !(line =~ /Testsuite summary for/m).nil? && test_section_started
        test_section_started = false
      end

      if test_section_started
        @test_lines << line
      end
    end  
  end

  def extractTestName(line)
    status_available = ['XPASS', 'PASS', 'XFAIL', 'FAIL', 'SKIP', 'ERROR']

    status_available.each{ |st_ava| break line.split(st_ava)[1].split(":")[1].strip if line.include?(st_ava) }
  end

  def analyze_tests
    @current_test = ""
    @test_lines.each do |line|
      # If the line contains a valid test case status
      if !(line =~ /PASS/m).nil? || !(line =~ /XPASS/m).nil? || !(line =~ /SKIP/m).nil? || !(line =~ /ERROR/m).nil? || !(line =~ /FAIL/m).nil? || !(line =~ /XFAIL/m).nil?
        # Test Name
        @current_test = extractTestName(line)

        # Ignore invalid test process (for instance, running a sample of examples from other language)
        if !@current_test.end_with?(".py", ".java")
          init_tests
          @tests_run = true
          add_framework 'cmakesummary'

          # Test Run
          @tests_runed << @current_test
          @num_tests_run += 1
          @tests_runed_num << 1

          # Tests duration (We do not have this information in the log)
          @test_duration += 0 #
          @tests_runed_duration << 0

          if !(line =~ /SKIP/m).nil?
            @num_tests_skipped += 1
          elsif  !(line =~ /FAIL/m).nil? || !(line =~ /XFAIL/m).nil?
            # If the test failed add to the failed test set
            @tests_failed << @current_test
            @num_tests_failed += 1
            @tests_failed_num << 1
          end
        end # valid test
      end
    end # end lines

    # Calculate the number of tests "ok"
    uninit_ok_tests
  end

  def tests_failed?
    return !@tests_failed.empty? || (!@num_tests_failed.nil? && @num_tests_failed > 0)
  end

end
