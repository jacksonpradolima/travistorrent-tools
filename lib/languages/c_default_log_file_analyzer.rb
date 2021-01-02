# A Mixin for the analysis of C build files. 
# The tests are executed by the command 'make  check-TESTS' and finish when 'Testsuite summary for' information appear

module CDefaultLogFileAnalyzer
    attr_reader :tests_failed, :tests_runed, :test_duration

  def init_deep    
    @tests_failed_lines = Array.new
    @tests_failed = Array.new
    @tests_failed_num = Array.new
    @tests_runed = Array.new
    @analyzer = 'cdefault'
  end

  def custom_analyze
    extract_tests
    analyze_tests
  end

  def extract_tests
    test_section_started = false
    
    @folds[@OUT_OF_FOLD].content.each do |line|

      if !(line =~ /Test project/).nil?
        test_section_started = true
      elsif !(line =~ /tests failed out of (\d*)/).nil? && test_section_started
        test_section_started = false
      end

      if test_section_started
        @test_lines << line
      end
    end
  end

  def analyze_tests
    @current_test = ""
    @test_status = ""
    @test_lines.each do |line|
      if !(line =~ /(\d*)\/(\d*) Test(\s+)#(\d*):(\s+)(\w+)(\s+)([.]{2,})(\s+)(\w+)(\s+)(.*) sec/).nil?
        init_tests
        @tests_run = true
        add_framework 'cdefault'

        # Current test case
        @current_test = $6
        # Test Case Status
        @test_status = $10

        # Test Run
        @num_tests_run += 1
        @tests_runed << @current_test
        
        # Tests duration
        @test_duration += $12.to_f
        
        if @test_status =~ '/Skipped/'.nil?
          @num_tests_skipped += 1
        end

        # If the test failed add to the failed test set
        if @test_status =~ '/Passed/'.nil?
          @num_tests_failed += 1
          @tests_failed << @current_test
        end
      end
    end # end lines

    # Calculate the number of tests "ok"
    uninit_ok_tests
  end

  def tests_failed?
    return !@tests_failed.empty? || (!@num_tests_failed.nil? && @num_tests_failed > 0)
  end

end
