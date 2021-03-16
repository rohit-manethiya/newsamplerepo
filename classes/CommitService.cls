public interface CommitService {
    String getPageHeader();
    GitCommit_PageBase loadAndValidateBaseRecords(String namespace, String usId, String snapshotId);
    PageReference returnParentRecord();
}