class FailedCommand < Exception
  getter :stdout, :stderr

  def initialize(message, @stdout, @stderr)
    super message
  end
end

module ShardRegistry
  module Factories
    def create_git_repository(project, *versions)
      Dir.cd(tmp_path) do
        run "git init #{project}"
      end

      Dir.mkdir(File.join(git_path(project), "src"))
      File.write(File.join(git_path(project), "src", "#{project}.cr"), "module #{project.capitalize}\nend")

      Dir.cd(git_path(project)) do
        run "git add src/#{project}.cr"
      end

      versions.each { |version| create_git_release project, version }
    end

    def create_git_release(project, version, shard = true)
      Dir.cd(git_path(project)) do
        if shard
          contents = shard.is_a?(String) ? shard : "name: #{project}\nversion: #{version}\n"
          create_shard project, contents
        end
        create_git_commit project, "release: v#{version}"
        run "git tag v#{version}"
      end
    end

    def create_git_commit(project, message = "new commit")
      Dir.cd(git_path(project)) do
        run "git add ."
        run "git commit --allow-empty -m '#{message}'"
      end
    end

    def create_shard(project, contents)
      create_file project, "shard.yml", contents
    end

    def create_file(project, filename, contents)
      Dir.cd(git_path(project)) do
        File.write filename, contents
      end
    end

    def git_commits(project)
      Dir.cd(git_path(project)) do
        run("git log --format='%H'", capture: true).not_nil!.strip.split("\n")
      end
    end

    def git_url(project)
      "file:///#{git_path(project)}"
    end

    def git_path(project)
      File.join(tmp_path, project.to_s)
    end

    def tmp_path
      @@tmp_path ||= begin
                       path = File.expand_path("../../.repositories", __FILE__)
                       Dir.mkdir(path) unless Dir.exists?(path)
                       path
                     end
    end

    def run(command, capture = false)
      # puts command
      output, error = MemoryIO.new, MemoryIO.new
      status = Process.run("/bin/sh", input: MemoryIO.new(command), output: output, error: error)

      if status.success?
        output.to_s if capture
      else
        raise FailedCommand.new("command failed: #{command}", output.to_s, error.to_s)
      end
    end
  end
end

class Minitest::Test
  include ShardRegistry::Factories
end
