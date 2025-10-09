//
//  ErrorScreen.swift
//  Trains
//
//  Created by Diana Viter on 07.08.2025.
//

import SwiftUI

struct ErrorScreen: View {
    @StateObject private var vm: ErrorScreenViewModel

    init(type: AppErrorType) {
        _vm = StateObject(wrappedValue: ErrorScreenViewModel(type: type))
    }

    var body: some View {
        VStack {
            Spacer()

            Image(vm.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 223, height: 223)
                .clipShape(RoundedRectangle(cornerRadius: 40))

            Text(vm.title)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 12)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ErrorScreen(type: .serverError)
}
