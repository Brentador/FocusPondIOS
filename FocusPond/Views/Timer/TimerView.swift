import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel = TimerViewModel()
    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.formatTime())
                .font(.largeTitle)
                .monospacedDigit()
        }
        
        HStack{
            Button("start") { viewModel.startTimer() }
            Button("stop") { viewModel.stopTimer() }
            Button("pause") { viewModel.pauseTimer() }
            Button("resume") { viewModel.resumeTimer() }
        }
        
        VStack {
            Text("Set Duration")
            
            HStack {
                Button("5"){
                    viewModel.setDuration(seconds: 5 * 60)
                }
                Button("10"){
                    viewModel.setDuration(seconds: 10 * 60)
                }
                Button("25"){
                    viewModel.setDuration(seconds: 25 * 60)
                }
            }
        }
        .padding()
    }
}


