//
//  ConfigList.swift
//  V2rayU
//
//  Created by yanue on 2024/11/30.
//

import SwiftUI

struct ConfigListView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var list: [ProfileModel] = []
    @State private var sortOrder: [KeyPathComparator<ProfileModel>] = []
    @State private var selection: Set<ProfileModel.ID> = []
    @State private var selectedRow: ProfileModel? = nil
    @State private var selectGroup: String = ""
    @State private var searchText = ""
    @State private var draggedRow: ProfileModel?

    var filteredAndSortedItems: [ProfileModel] {
        let filtered = viewModel.list.filter { item in
            (selectGroup == "" || selectGroup == item.subid) &&
                (searchText.isEmpty || item.address.lowercased().contains(searchText.lowercased()) || item.remark.lowercased().contains(searchText.lowercased()))
        }
        .sorted(using: sortOrder)
        // 循环增加序号
        filtered.enumerated().forEach { index, item in
            item.index = index
        }
        return filtered
    }

    var body: some View {
        VStack {
            HStack {
                Text("Prixies")
                    .font(.title)
                    .fontWeight(.bold)
                
                Picker("选择组", selection: $selectGroup) {
//                    ForEach(viewModel.groups) { group in // 使用 groups 数组并遍历
//                        Text(group).tag(group) // 使用 .tag 来绑定选中的项
//                    }
                }
                .pickerStyle(MenuPickerStyle()) // 可根据需要选择不同的 Picker 样式
                .padding()

                Text("搜索")
                TextField("Search by Address or Remark", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("刷新") {
                    loadData()
                }
                Button("Ping") {
                    withAnimation {
                    }
                }

                Button("删除") {
                    withAnimation {
                        // 删数据
                        for selectedID in self.selection {
                            viewModel.delete(uuid: selectedID) // 使用找到的模型的 uuid 字段
                        }
                        // 移除选择
                        selection.removeAll()
                    }
                }
                .disabled(selection.isEmpty)

                Button("新增") {
                    withAnimation {
                        let newProxy = ProfileModel(remark: "New Remark", protocol: .trojan, address: "newAddress", port: 443, password: UUID().uuidString, encryption: "auto")
                        self.selectedRow = newProxy
                    }
                }
            }

            Table(of: ProfileModel.self, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("#") { item in
                    Text("\(item.index + 1)") // 显示 1-based 索引
                }
                .width(30)
                TableColumn("Type", value: \.protocol.rawValue)
                TableColumn("Remark") { row in
                    // 双击事件
                    Text(row.remark).onTapGesture(count: 2) {
                        selectedRow = row
                    }
                }
                TableColumn("Address", value: \.address)
                TableColumn("Port", value: \.port.description)
                TableColumn("Network", value: \.network.rawValue)
                TableColumn("TLS", value: \.security.rawValue)
            } rows: {
                ForEach(filteredAndSortedItems) { row in
                    TableRow(row)
                        // 启用拖拽功能
                        .draggable(row)
                        // 右键菜单
                        .contextMenu {
                            contextMenuProvider(item: row)
                        }
                }
                // 处理拖动逻辑
                .dropDestination(for: ProfileModel.self, action: handleDrop)
            }
        }
        .sheet(item: $selectedRow) { row in
            VStack {
                Button("Close") {
                    viewModel.upsert(item: row)
                    // 如果需要关闭 `sheet`，将 `selectedRow` 设置为 `nil`
                    selectedRow = nil
                }
                ConfigView(item: row)
                    .padding()
            }
        }
        .task {
            loadData()
        }
    }

    // 处理拖拽排序逻辑:
    // 参考: https://levelup.gitconnected.com/swiftui-enable-drag-and-drop-for-table-rows-with-custom-transferable-aa0e6eb9f5ce
    func handleDrop(index: Int, rows: [ProfileModel]) {
        guard let firstRow = rows.first, let firstRemoveIndex = list.firstIndex(where: { $0.id == firstRow.id }) else { return }

        list.removeAll(where: { row in
            rows.contains(where: { insertRow in insertRow.id == row.id })
        })

        list.insert(contentsOf: rows, at: index > firstRemoveIndex ? (index - 1) : index)
    }

    private func contextMenuProvider(item: ProfileModel) -> some View {
        Group {
            Button("Edit") {
                self.selectedRow = item
            }

            Divider()

            Button("Ping") {
                // Handle ping action
            }

            Button("Delete") {
                // Handle another action
                print("item.uuid", item.id, item.uuid)
                viewModel.delete(uuid: item.uuid)
            }
        }
    }

    private func loadData() {
        viewModel.getList() // Load data when the view appears
    }
}

#Preview {
    ConfigListView()
}