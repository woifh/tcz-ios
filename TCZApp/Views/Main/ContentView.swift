import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
