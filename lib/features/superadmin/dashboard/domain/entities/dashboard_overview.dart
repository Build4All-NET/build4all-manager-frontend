class DashboardOverview {
  final int totalProjects;
  final int activeProjects;
  final int inactiveProjects;

 
  final int pendingUpgradeRequests;

  const DashboardOverview({
    required this.totalProjects,
    required this.activeProjects,
    required this.inactiveProjects,
    this.pendingUpgradeRequests = 0,
  });
}
