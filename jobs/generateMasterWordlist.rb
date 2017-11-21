# Module for generating a master wordlist, a unique set of words of all wordlists.
module GenerateMasterWordlist
  @queue = :management

  def self.perform()
    # Setup Logger
    logger = Logger.new('logs/jobs/generateMasterWordlist.log', 'daily')
    if ENV['RACK_ENV'] == 'development'
      logger.level = Logger::DEBUG
    else
      logger.level = Logger::INFO
    end

    logger.debug('Generate Master Wordlist Class() - has started')

    # Set existing Master Wordlist status to pending
    logger.debug('Setting Master Wordlist status to pending.')
    master_wordlist = Wordlists.first(type: :dynamic, name: 'Master Wordlist')
    master_wordlist.status = 'pending'
    master_wordlist.save

    # Remove old master wordlist file/path
    File.delete(master_wordlist.path) if File.exist?(master_wordlist.path)

    # Generate new master wordlist
    # TODO
    # We could get this via the facter gem
    # Facter.value('processors'['count'])
    cpu_count = `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    shell_cmd = 'sort --parallel ' + cpu_count.to_s + ' -u '
    @wordlists = Wordlists.all(type: :static)
    @wordlists.each do |entry|
      shell_cmd = shell_cmd + entry.path.to_s + ' '
    end

    # We move to temp to prevent wordlist importer from accidentally loading the master wordlist too early
    shell_cmd += '-o control/tmp/MasterWordlist.txt'
    logger.debug('Shell CMD: ' + shell_cmd)
    system(shell_cmd)

    shell_mv_cmd = 'mv control/tmp/MasterWordlist.txt control/wordlists/MasterWordlist.txt'
    system(shell_mv_cmd)

    # Recognize size diff
    size = File.foreach(master_wordlist.path).inject(0) do |c|
      c + 1
    end
    master_wordlist.size = size
    master_wordlist.lastupdated = Time.now
    master_wordlist.checksum = nil
    master_wordlist.save

    # Generate Checksum
    Resque.enqueue(WordlistChecksum)

    logger.debug('Generate Master Wordlist Class() - has completed')
  end
end