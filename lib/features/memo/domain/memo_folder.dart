/// 백엔드 `MemoApiDto.FolderResponse` 매핑 (plain class).
///
/// `parentId == null` 이면 루트 폴더. `sortOrder` 로 형제 정렬.
class MemoFolder {
  const MemoFolder({
    required this.rowId,
    this.userRowId,
    this.parentId,
    required this.folderName,
    this.sortOrder,
    this.createAt,
    this.modifyAt,
  });

  final int rowId;
  final int? userRowId;
  final int? parentId;
  final String folderName;
  final int? sortOrder;
  final String? createAt;
  final String? modifyAt;

  factory MemoFolder.fromJson(Map<String, dynamic> json) {
    return MemoFolder(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      folderName: (json['folderName'] as String?) ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
    );
  }
}

/// 트리 노드 — 클라이언트 측에서 평면 list 를 부모-자식 트리로 변환.
class MemoFolderNode {
  MemoFolderNode({required this.folder, this.children = const []});
  final MemoFolder folder;
  List<MemoFolderNode> children;

  /// 평면 [list] 를 트리로 변환 (root 노드들 반환).
  static List<MemoFolderNode> buildTree(List<MemoFolder> list) {
    final byId = <int, MemoFolderNode>{
      for (final f in list) f.rowId: MemoFolderNode(folder: f, children: []),
    };
    final roots = <MemoFolderNode>[];
    for (final node in byId.values) {
      final pid = node.folder.parentId;
      if (pid == null || !byId.containsKey(pid)) {
        roots.add(node);
      } else {
        byId[pid]!.children.add(node);
      }
    }
    int sort(MemoFolderNode a, MemoFolderNode b) {
      final ao = a.folder.sortOrder ?? 0;
      final bo = b.folder.sortOrder ?? 0;
      if (ao != bo) return ao.compareTo(bo);
      return a.folder.folderName.compareTo(b.folder.folderName);
    }

    void sortRec(List<MemoFolderNode> ns) {
      ns.sort(sort);
      for (final n in ns) {
        sortRec(n.children);
      }
    }

    sortRec(roots);
    return roots;
  }
}
