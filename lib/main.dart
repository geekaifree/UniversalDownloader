import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const DownloaderApp());
class DownloaderApp extends StatelessWidget {
  const DownloaderApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '万能下载器', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true, brightness: Brightness.dark),
    home: const DownloaderHomePage());
}

class DownloadTask {
  String id, url, name, size, status, speed;
  double progress;
  Timer? timer;
  DownloadTask({required this.id, required this.url, required this.name, required this.size, this.status = '等待中', this.speed = '0 KB/s', this.progress = 0});
}

class DownloaderHomePage extends StatefulWidget {
  const DownloaderHomePage({super.key});
  @override
  State<DownloaderHomePage> createState() => _DownloaderHomePageState();
}

class _DownloaderHomePageState extends State<DownloaderHomePage> {
  List<DownloadTask> _tasks = [];
  final _urlCtrl = TextEditingController();
  final _rng = Random();

  void _addTask() {
    if (_urlCtrl.text.isEmpty) return;
    final url = _urlCtrl.text;
    final name = url.split('/').last.split('?').first;
    final size = '${50 + _rng.nextInt(500)}MB';
    final task = DownloadTask(id: DateTime.now().millisecondsSinceEpoch.toString(), url: url, name: name.isEmpty ? 'download_${_tasks.length + 1}' : name, size: size);
    setState(() => _tasks.insert(0, task));
    _urlCtrl.clear();
    _startDownload(task);
  }

  void _startDownload(DownloadTask task) {
    setState(() => task.status = '下载中');
    task.timer = Timer.periodic(Duration(milliseconds: 200 + _rng.nextInt(300)), (_) {
      if (task.progress >= 1) { task.timer?.cancel(); setState(() => task.status = '完成'); return; }
      setState(() {
        task.progress += 0.01 + _rng.nextDouble() * 0.03;
        task.speed = '${(100 + _rng.nextInt(5000)).toString()} KB/s';
        if (task.progress >= 1) { task.progress = 1; task.status = '完成'; task.speed = '0 KB/s'; }
      });
    });
  }

  void _pauseTask(DownloadTask task) { task.timer?.cancel(); setState(() => task.status = '已暂停'); }
  void _resumeTask(DownloadTask task) => _startDownload(task);
  void _deleteTask(DownloadTask task) { task.timer?.cancel(); setState(() => _tasks.removeWhere((t) => t.id == task.id)); }

  @override
  void dispose() { for (var t in _tasks) { t.timer?.cancel(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⬇️ 万能下载器'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('添加下载'),
          content: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder(), hintText: 'https://example.com/file.zip'), autofocus: true),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { _addTask(); Navigator.pop(ctx); }, child: const Text('下载'))],
        )), tooltip: '添加下载'),
      ]),
      body: Column(children: [
        // 快速添加
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: TextField(controller: _urlCtrl, decoration: InputDecoration(hintText: '输入URL或磁力链...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)), prefixIcon: const Icon(Icons.link), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), onSubmitted: (_) => _addTask())),
          const SizedBox(width: 8),
          FilledButton(onPressed: _addTask, child: const Text('下载')),
        ])),
        // 统计
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          _buildStat('全部', _tasks.length, Colors.blue),
          _buildStat('下载中', _tasks.where((t) => t.status == '下载中').length, Colors.green),
          _buildStat('已完成', _tasks.where((t) => t.status == '完成').length, Colors.grey),
        ])),
        const SizedBox(height: 8),
        // 任务列表
        Expanded(child: _tasks.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_download, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('输入URL开始下载', style: TextStyle(color: Colors.grey.shade500))])) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _tasks.length, itemBuilder: (ctx, i) {
          final t = _tasks[i];
          return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(t.status == '完成' ? Icons.check_circle : t.status == '下载中' ? Icons.downloading : Icons.pause_circle, color: t.status == '完成' ? Colors.green : t.status == '下载中' ? Colors.blue : Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(t.size, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: t.progress, backgroundColor: Colors.grey.shade200, color: t.status == '完成' ? Colors.green : Colors.blue),
            const SizedBox(height: 4),
            Row(children: [
              Text(t.status, style: TextStyle(fontSize: 12, color: t.status == '完成' ? Colors.green : Colors.grey)),
              const Spacer(),
              if (t.status == '下载中') Text(t.speed, style: const TextStyle(fontSize: 12, color: Colors.blue)),
              const SizedBox(width: 8),
              Text('${(t.progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (t.status == '下载中') IconButton(icon: const Icon(Icons.pause, size: 20), onPressed: () => _pauseTask(t), tooltip: '暂停'),
              if (t.status == '已暂停') IconButton(icon: const Icon(Icons.play_arrow, size: 20, color: Colors.green), onPressed: () => _resumeTask(t), tooltip: '继续'),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _deleteTask(t), tooltip: '删除'),
            ]),
          ])));
        })),
      ]),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Padding(padding: const EdgeInsets.only(right: 16), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text('$label: $count', style: TextStyle(fontSize: 12, color: color))]));
  }
}
