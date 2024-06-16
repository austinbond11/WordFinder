// ContentView.swift
// WordScramble
// Created by Austin Bond on 6/15/24.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - State Properties
    
    // Array to hold words used by the player
    @State private var usedWords = [String]()
    
    // The original word from which new words are to be created
    @State private var rootWord = ""
    
    // The new word entered by the player
    @State private var newWord = ""
    
    // Title of the error alert
    @State private var errorTitle = ""
    
    // Message of the error alert
    @State private var errorMessage = ""
    
    // Bool to indicate whether the error alert should be shown
    @State private var showingError = false
    
    // Player's current score
    @State private var score = 0
    
    // Focus state for the TextField to manage focus behavior
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                // Displays the root word at the top of the view
                Text(rootWord)
                    .font(.title)
                    .padding(.top)

                // Input field where the player enters new words
                TextField("Enter your word", text: $newWord)
                    .textInputAutocapitalization(.never) // Disable automatic capitalization
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color(UIColor.secondarySystemBackground))
                    .focused($isTextFieldFocused) // Tie the focus state to this TextField

                // Container to provide dynamic sizing for the ScrollView
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading) {
                            // Iterate over the used words and display each with an icon indicating the word length
                            ForEach(usedWords, id: \.self) { word in
                                HStack {
                                    Image(systemName: "\(word.count).circle")
                                    Text(word)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(width: geometry.size.width, alignment: .leading) // Ensures content is left-aligned
                    }
                }

                // Displays the current score
                Text("Score: \(score)")
                    .font(.title2)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding([.horizontal, .bottom])
            }
            .navigationTitle("WordFinder") // Title of the navigation bar
            .onSubmit(addNewWord) // Call addNewWord() when the TextField is submitted
            .onAppear(perform: startGame) // Call startGame() when the view appears
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) { } // Dismiss button for the alert
            } message: {
                Text(errorMessage) // Alert message content
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Word", action: startGame) // Button to start a new game
                }
            }
        }
    }

    // MARK: - Functions
    
    // Function to add a new word to the list of used words
    func addNewWord() {
        // Normalize the input word by converting it to lowercase and trimming whitespace and newlines
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Guard clauses to handle various validation and error cases
        guard answer.count > 0 else { return } // Ensure the word is not empty

        guard answer.count > 2 else {
            wordError(title: "Word is too short", message: "Make a longer word!") // Ensure the word length is greater than 2
            return
        }

        guard answer != rootWord else {
            wordError(title: "Word matches the original", message: "Make a word from letters of the original!") // Ensure the word does not match the root word
            return
        }

        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original!") // Ensure the word has not been used before
            return
        }

        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!") // Ensure the word can be made from the letters of the root word
            return
        }

        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know?") // Ensure the word is a valid word
            return
        }

        // If all checks are passed, add the word to the usedWords array with animation
        withAnimation {
            usedWords.insert(answer, at: 0)
        }

        // Update the score based on the length of the new word
        score += answer.count
        // Clear the text field for new input
        newWord = ""
        
        // Keep the TextField focused
        isTextFieldFocused = true
    }

    // Function to start the game by loading a random root word from a resource file
    func startGame() {
        // Find the URL of the start.txt resource file
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // Try to load the contents of the file into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // Split the string into an array of words and choose a random word as the root word
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        // If the resource file could not be loaded, terminate the app with an error
        fatalError("Could not load start.txt from bundle.")
    }

    // Function to check if the word has not been used before
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }

    // Function to check if the word can be made from the root word's letters
    func isPossible(word: String) -> Bool {
        // Create a mutable copy of the root word
        var tempWord = rootWord

        // Iterate over each letter in the input word
        for letter in word {
            // Attempt to find the letter in the mutable copy of the root word
            if let pos = tempWord.firstIndex(of: letter) {
                // Remove the found letter from the mutable copy to avoid counting it twice
                tempWord.remove(at: pos)
            } else {
                // If the letter is not found, the word cannot be made from the root word
                return false
            }
        }
        return true
    }

    // Function to check if the word is a valid English word using the UITextChecker
    func isReal(word: String) -> Bool {
        // Create an instance of UITextChecker for spell checking
        let checker = UITextChecker()
        // Define the range of the word to be checked
        let range = NSRange(location: 0, length: word.utf16.count)
        // Check the word for misspellings
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        // If no misspelled range is found, the word is valid
        return misspelledRange.location == NSNotFound
    }

    // Function to show an error alert with the provided title and message
    func wordError(title: String, message: String) {
        // Set the title and message for the alert
        errorTitle = title
        errorMessage = message
        // Set showingError to true to present the alert
        showingError = true
    }
}

#Preview {
    ContentView()
}
