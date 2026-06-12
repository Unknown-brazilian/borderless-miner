/// Representa um "job" recebido via mining.notify do Stratum.
class MiningJob {
  final String jobId;
  final String prevhash;
  final String coinb1;
  final String coinb2;
  final List<String> merkleBranches;
  final String version; // hex
  final String nbits; // hex
  final String ntime; // hex
  final bool cleanJobs;

  MiningJob({
    required this.jobId,
    required this.prevhash,
    required this.coinb1,
    required this.coinb2,
    required this.merkleBranches,
    required this.version,
    required this.nbits,
    required this.ntime,
    required this.cleanJobs,
  });

  /// mining.notify params:
  /// [job_id, prevhash, coinb1, coinb2, merkle_branch[], version, nbits, ntime, clean_jobs]
  factory MiningJob.fromNotify(List params) {
    return MiningJob(
      jobId: params[0] as String,
      prevhash: params[1] as String,
      coinb1: params[2] as String,
      coinb2: params[3] as String,
      merkleBranches: (params[4] as List).cast<String>(),
      version: params[5] as String,
      nbits: params[6] as String,
      ntime: params[7] as String,
      cleanJobs: params.length > 8 ? (params[8] == true) : true,
    );
  }

  Map<String, dynamic> toMap() => {
        'jobId': jobId,
        'prevhash': prevhash,
        'coinb1': coinb1,
        'coinb2': coinb2,
        'merkleBranches': merkleBranches,
        'version': version,
        'nbits': nbits,
        'ntime': ntime,
        'cleanJobs': cleanJobs,
      };

  factory MiningJob.fromMap(Map m) => MiningJob(
        jobId: m['jobId'],
        prevhash: m['prevhash'],
        coinb1: m['coinb1'],
        coinb2: m['coinb2'],
        merkleBranches: (m['merkleBranches'] as List).cast<String>(),
        version: m['version'],
        nbits: m['nbits'],
        ntime: m['ntime'],
        cleanJobs: m['cleanJobs'],
      );
}
