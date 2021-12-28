part of '../drive_detail_page.dart';

Widget _buildDataTable(BuildContext context, DriveDetailLoadSuccess state) {
  return DriveDataTable(
    driveDetailState: state,
    context: context,
  );
}

class DriveDataTable extends StatefulWidget {
  final DriveDetailLoadSuccess driveDetailState;
  final BuildContext context;
  const DriveDataTable({
    Key? key,
    required this.driveDetailState,
    required this.context,
  }) : super(key: key);

  @override
  State<DriveDataTable> createState() => _DriveDataTableState();
}

class _DriveDataTableState extends State<DriveDataTable> {
  int rowsPerPage = 25;
  List<int> availableRowsPerPage = [25, 50, 75, 100];
  @override
  void initState() {
    calculateRowsPerPage();
    super.initState();
  }

  void calculateRowsPerPage() {
    final itemCount = widget.driveDetailState.currentFolder.files.length +
        widget.driveDetailState.currentFolder.subfolders.length;
    if (itemCount < rowsPerPage) {
      rowsPerPage = itemCount;
      availableRowsPerPage.insert(0, rowsPerPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        children: [
          Theme(
            data: ThemeData(
              cardTheme: CardTheme(
                color: Colors.transparent,
                elevation: 0.0,
              ),
            ),
            child: CustomPaginatedDataTable(
              showCheckboxColumn: false,
              columns: _buildTableColumns(context),
              sortColumnIndex: DriveOrder.values
                  .indexOf(widget.driveDetailState.contentOrderBy),
              sortAscending: widget.driveDetailState.contentOrderingMode ==
                  OrderingMode.asc,
              rowsPerPage: widget.driveDetailState.currentFolder.files.length +
                          widget.driveDetailState.currentFolder.subfolders
                              .length <
                      rowsPerPage
                  ? widget.driveDetailState.currentFolder.files.length +
                      widget.driveDetailState.currentFolder.subfolders.length
                  : rowsPerPage,
              availableRowsPerPage: availableRowsPerPage,
              onRowsPerPageChanged: (value) =>
                  setState(() => rowsPerPage = value!),
              source: DriveDetailDataTableSource(
                context: context,
                files: widget.driveDetailState.currentFolder.files
                    .map(
                      (file) => DriveTableFile(
                        file: file,
                        selected:
                            file.id == widget.driveDetailState.selectedItemId,
                        onPressed: () async {
                          final bloc = context.read<DriveDetailCubit>();
                          if (file.id ==
                              widget.driveDetailState.selectedItemId) {
                            bloc.toggleSelectedItemDetails();
                          } else {
                            await bloc.selectItem(file.id);
                          }
                        },
                      ),
                    )
                    .toList(),
                folders: widget.driveDetailState.currentFolder.subfolders
                    .map(
                      (folder) => DriveTableFolder(
                        folder: folder,
                        selected:
                            folder.id == widget.driveDetailState.selectedItemId,
                        onPressed: () {
                          final bloc = context.read<DriveDetailCubit>();
                          if (folder.id ==
                              widget.driveDetailState.selectedItemId) {
                            bloc.openFolder(path: folder.path);
                          } else {
                            bloc.selectItem(
                              folder.id,
                              isFolder: true,
                            );
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<DataColumn> _buildTableColumns(BuildContext context) {
  final onSort = (columnIndex, sortAscending) =>
      context.read<DriveDetailCubit>().sortFolder(
            contentOrderBy: DriveOrder.values[columnIndex],
            contentOrderingMode:
                sortAscending ? OrderingMode.asc : OrderingMode.desc,
          );
  return [
    DataColumn(
        label: Text(
          'Name',
          overflow: TextOverflow.ellipsis,
        ),
        onSort: onSort),
    DataColumn(
        label: Text(
          'File size',
          overflow: TextOverflow.ellipsis,
        ),
        onSort: onSort),
    DataColumn(
        label: Text(
          'Last updated',
          overflow: TextOverflow.ellipsis,
        ),
        onSort: onSort),
  ];
}
