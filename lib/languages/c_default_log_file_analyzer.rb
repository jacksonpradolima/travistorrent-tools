# A Mixin for the analysis of C build files. 
# The tests are executed by the command 'make  check-TESTS' and finish when 'Testsuite summary for' information appear

module CDefaultLogFileAnalyzer
    attr_reader :tests_failed, :tests_runed, :test_duration

  def init_deep    
    @tests_failed_lines = Array.new
    @tests_failed = Array.new
    @tests_failed_num = Array.new
    @tests_runed = Array.new
    @tests_runed_num = Array.new
    @tests_runed_duration = Array.new
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
        # Current test case
        @current_test = $6

        # Ignore invalid test process (for instance, running a sample of examples from other language)
        if !@current_test.end_with?(".py", ".java")
          init_tests
          @tests_run = true
          add_framework 'cdefault'

          # Test Case Status
          @test_status = $10

          # Test Run
          @tests_runed << @current_test
          @num_tests_run += 1
          @tests_runed_num << 1

          # Tests duration
          @duration = $12
          @test_duration += @duration.to_f
          @tests_runed_duration << @duration

          if @test_status.include?('Skipped')
            @num_tests_skipped += 1
          end

          # If the test not passed, it failed, so we add to the failed test set
          if !@test_status.include?('Passed')
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
