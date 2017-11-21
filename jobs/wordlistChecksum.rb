# this job generates checksums for each wordlist
#
module WordlistChecksum
  @queue = :management
  def self.perform()
    # Setup Logger
    logger = Logger.new('logs/jobs/wordlistChecksum.log', 'daily')
    if ENV['RACK_ENV'] == 'development'
      logger.level = Logger::DEBUG
    else
      logger.level = Logger::INFO
    end

    logger.debug('Wordlist Checksum Class() - has started')

    # Identify all wordlists without checksums
    @wordlist = Wordlists.all(checksum: nil)
    @wordlist.each do |wordlist|
      # generate checksum
      logger.info('generating checksum for: ' + wordlist.path.to_s)
      checksum = Digest::SHA2.hexdigest(File.read(wordlist.path))

      # save checksum to database
      wordlist.checksum = checksum
      wordlist.status = 'ready' if wordlist.status == 'pending'
      wordlist.save
    end

    logger.debug('Wordlist Checksum Class() - has completed')
  end
end
