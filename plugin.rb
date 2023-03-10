Cocov::PluginKit.run do
  # Find files. Notice we are on alpine, so this is Busybox's grep
  begin
    files = exec("grep -rIlE '^#![[:blank:]]*/bin/(ba|a)?sh' ./").split("\n")
  rescue Cocov::PluginKit::Exec::ExecutionError => e
    puts e.stdout
    puts e.stderr
    puts "ERROR: Process grep exited with status #{e.status}"
    exit 1
  end

  exit 0 if files.empty?

  errors = files.map do |f|
    exec("shellcheck --format=json #{f}")
  rescue Cocov::PluginKit::Exec::ExecutionError => e
    next e.stdout if e.status == 1

    puts e.stdout
    puts e.stderr
    puts "ERROR: Process shellcheck exited with status #{e.status}"
    exit 1
  end

  errors
    .map(&:strip)
    .reject(&:empty?)
    .map { JSON.parse(_1) }
    .each do |list|
      list.each do |err|
        file, line_start, line_end, message, code, level = err.slice("file", "line", "endLine", "message", "code", "level").values
        kind = level == "style" ? :style : :bug
        if level != "style"
          message = "(#{level}): #{message}"
        end

        # TODO: C#{level} could link to https://www.shellcheck.net/wiki/C#{level}
        # when minimal markdown support is implemented.
        message = "C#{code} #{message}"
        uid = sha1([file, line_start, line_end, code, level].join(''))
        emit_issue(kind:, file:, line_start:, line_end:, message:, uid:)
      end
    end
end
