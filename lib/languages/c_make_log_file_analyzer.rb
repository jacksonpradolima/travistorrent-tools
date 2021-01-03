# A Mixin for the analysis of C build files. 
# The tests are executed by the command 'make  check-TESTS' and finish when 'Testsuite summary for' information appear

module CMakeLogFileAnalyzer
  attr_reader :tests_failed, :tests_failed_num, :test_duration,  :tests_runed, :tests_runed_duration

  def init_deep    
    @tests_failed_lines = Array.new
    @tests_failed = Array.new
    @tests_failed_num = Array.new
    @tests_runed = Array.new
    @tests_runed_num = Array.new
    @tests_runed_duration = Array.new
    @analyzer = 'cmake'
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
      elsif !(line =~ /All (\d*) tests passed/).nil? && test_section_started
        test_section_started = false
      elsif !(line =~ /(\d*) of (\d*) tests failed/).nil? && test_section_started
        test_section_started = false
      end

      if test_section_started
        @test_lines << line
      end
    end
  end

  def analyze_tests
    @current_test = ""
    @test_lines.each do |line|
       # Get the Test Name
      if line.to_s.include?("Running suite(s):")
        @current_test = line.split("Running suite(s):")[1].strip
      end
      
      if !(line =~ /(\d*)%: Checks: (\d*), Failures: (\d*), Errors: (\d*)/).nil?
        # Ignore invalid test process (for instance, running a sample of examples from other language)
        if !@current_test.end_with?(".py", ".java")
          init_tests
          @tests_run = true
          add_framework 'cmake'

          # Test Run
          @tests_runed << @current_test
          @num_run = $2.to_i
          @num_tests_run += @num_run
          @tests_runed_num << @num_run

           # Tests failed
          @num_failed = $3.to_i + $4.to_i
          @num_tests_failed += @num_failed

          # Tests duration (We do not have this information in the log)
          @test_duration += 0 #
          @tests_runed_duration << 0

          # If the test failed add to the failed test set
          if @num_failed > 0
            @tests_failed << @current_test
            @tests_failed_num << @num_failed
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
