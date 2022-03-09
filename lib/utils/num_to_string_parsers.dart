String fileAndFolderCountsToString({
  required int folderCount,
  required int fileCount,
}) {
  // FIXME: context is not available here. Internationalization cannot be applied
  final folderSuffix = folderCount == 1 ? 'folder' : 'folders';
  final fileSuffix = fileCount == 1 ? 'file' : 'files';

  return '$folderCount $folderSuffix, $fileCount $fileSuffix';
}