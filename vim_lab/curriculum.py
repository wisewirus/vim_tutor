"""Each exercise specifies an outcome, leaving the learner free to use real Vim."""


def move(prompt, hint, row, col):
    return {"kind": "cursor", "prompt": prompt, "hint": hint, "target": [row, col]}


def text(prompt, hint, *lines):
    return {"kind": "text", "prompt": prompt, "hint": hint, "target": list(lines)}


def lesson(id, chapter, title, minutes, intro, keys, lines, cursor, goals):
    return {
        "id": id,
        "chapter": chapter,
        "title": title,
        "minutes": minutes,
        "intro": intro,
        "keys": keys,
        "lines": lines,
        "cursor": cursor,
        "goals": goals,
    }


CHAPTERS = [
    "Get moving",
    "Add & edit",
    "Undo & reuse",
    "Select & change",
    "Work smarter",
    "Bring it together",
]


LESSONS = [
    lesson(
        "home-row", 0, "Home row", 2,
        "In Normal mode, your fingers are the navigation. Reach each highlighted dot without changing the text.",
        [["h", "left"], ["j", "down"], ["k", "up"], ["l", "right"]],
        ["@ . . . . . .", ". . . . . . .", ". . . . . . .", ". . . . . . ."], [1, 1],
        [
            move("Move right to the highlighted dot on line 1.", "Press l six times. The cursor starts on @.", 1, 7),
            move("Move down to the highlighted dot on line 3.", "Press j twice. Your column stays the same.", 3, 7),
            move("Move left to the highlighted dot on line 3.", "Press h four times.", 3, 3),
            move("Move up to the highlighted dot on line 1.", "Press k twice.", 1, 3),
        ],
    ),
    lesson(
        "words", 0, "Word by word", 2,
        "Travel in words instead of characters. w finds the next word, e finds its end, and b takes you back.",
        [["w", "next word"], ["e", "end of word"], ["b", "previous word"]],
        ["small steps make strong habits."], [1, 1],
        [
            move("Jump to the s in steps.", "Press w once.", 1, 7),
            move("Move to the last s in steps.", "Press e once.", 1, 11),
            move("Go back to the start of steps.", "Press b once.", 1, 7),
        ],
    ),
    lesson(
        "line-edges", 0, "The edges of a line", 2,
        "A line has three useful landmarks: its first column, its first visible character, and its last character.",
        [["0", "first column (zero)"], ["^", "first nonblank"], ["$", "last character"]],
        ["    meet me at the edges"], [1, 12],
        [
            move("Jump to the final s in edges.", "Press $. On most keyboards, that is Shift + 4.", 1, 24),
            move("Jump to the m in meet, past the indentation.", "Press ^. It skips the four leading spaces.", 1, 5),
            move("Jump to the very first column, including spaces.", "Press 0 (zero), not the letter o.", 1, 1),
        ],
    ),
    lesson(
        "file-jumps", 0, "Around the file", 2,
        "Jump straight to a line. gg goes to the top; G goes to the bottom. A number before G picks a line.",
        [["gg", "first line"], ["G", "last line"], ["3G", "line 3"]],
        ["the beginning", "a small step", "your third stop", "you are here", "a little further", "almost there", "the destination"], [4, 1],
        [
            move("Go to the first character of line 1.", "Press g twice: gg.", 1, 1),
            move("Go to the first character of the last line.", "Press capital G (Shift + g).", 7, 1),
            move("Go directly to the first character of line 3.", "Type 3G.", 3, 1),
        ],
    ),
    lesson(
        "find-character", 0, "Find a character", 2,
        "Find a character on the current line. f lands on it; t stops just before it. Semicolon repeats the last find.",
        [["f{char}", "find forward"], [";", "repeat the find"], ["t{char}", "stop before a character"]],
        ["red, green, blue, green."], [1, 1],
        [
            move("Find the first comma.", "Type f, (f followed by a comma).", 1, 4),
            move("Repeat that find to reach the next comma.", "Press ; once.", 1, 11),
            move("Stop just before the period at the end.", "Type t. (t followed by a period).", 1, 23),
        ],
    ),
    lesson(
        "search", 0, "Follow a search", 2,
        "Search across the file with / and Enter. n follows the next match; N goes back to the previous match.",
        [["/word ↵", "search forward"], ["n", "next match"], ["N", "previous match"]],
        ["follow the amber light", "small steps become habits", "the amber light is ahead", "keep going toward amber"], [1, 1],
        [
            move("Search for amber and land on the first a.", "Type /amber and press Enter.", 1, 12),
            move("Go to amber on line 3.", "Press n.", 3, 5),
            move("Return to amber on line 1.", "Press capital N.", 1, 12),
        ],
    ),
    lesson(
        "insert", 1, "Start inserting", 2,
        "Vim starts in Normal mode. i enters Insert mode before the cursor. Type your text, then press Esc to finish.",
        [["i", "insert before cursor"], ["Esc", "return to Normal mode"]],
        ["Vim fun."], [1, 5],
        [text("Turn this into Vim is fun. Finish in Normal mode.", "Press i, type is followed by a space, then press Esc.", "Vim is fun.")],
    ),
    lesson(
        "append", 1, "Add after the cursor", 1,
        "a starts typing after the current character. Use it to extend a word or add something at the end.",
        [["a", "append after cursor"], ["Esc", "finish editing"]],
        ["I learn Vim"], [1, 11],
        [text("Make the line read I learn Vim daily.", "Press a, type a space and daily., then press Esc.", "I learn Vim daily.")],
    ),
    lesson(
        "insert-edges", 1, "Insert at the edges", 2,
        "Capital A appends at the end of a line. Capital I inserts before its first nonblank character.",
        [["A", "append at line end"], ["I", "insert at line start"]],
        ["small steps"], [1, 6],
        [
            text("Add a period to the end of the line.", "Press A, type a period, then Esc.", "small steps."),
            text("Add Take and a space at the beginning.", "Press I, type Take followed by a space, then Esc.", "Take small steps."),
        ],
    ),
    lesson(
        "open-lines", 1, "Make a little space", 2,
        "o opens a new line below you. Capital O opens one above. Both put you straight into Insert mode.",
        [["o", "new line below"], ["O", "new line above"]],
        ["first line", "third line"], [1, 1],
        [
            text("Add second line between the two existing lines.", "Press o, type second line, then Esc.", "first line", "second line", "third line"),
            text("Add a bonus line above second line.", "With the cursor on second line, press O, type a bonus line, then Esc.", "first line", "a bonus line", "second line", "third line"),
        ],
    ),
    lesson(
        "small-fixes", 1, "Fix one character", 2,
        "Small repairs stay in Normal mode. x deletes the character under the cursor; r replaces it with the next character you type.",
        [["x", "delete a character"], ["r{char}", "replace a character"]],
        ["Vim is funn.", "Keep it cozl."], [1, 11],
        [
            text("Remove the extra n so line 1 reads Vim is fun.", "The cursor is on the extra n. Press x.", "Vim is fun.", "Keep it cozl."),
            text("Replace the l in cozl with y.", "Type j$h to reach the l, then ry to replace it.", "Vim is fun.", "Keep it cozy."),
        ],
    ),
    lesson(
        "delete-line", 1, "Delete a whole line", 1,
        "Pressing d twice deletes the entire current line, including its line break. The other lines close the gap.",
        [["dd", "delete current line"]],
        ["keep the first line", "remove this whole line", "keep the last line"], [2, 1],
        [text("Delete the middle line and keep the other two.", "Press dd.", "keep the first line", "keep the last line")],
    ),
    lesson(
        "delete-motions", 2, "Give delete a motion", 2,
        "Vim commands combine an action and a motion. d means delete; w and $ describe how far to go.",
        [["dw", "delete to next word"], ["d$", "delete to line end"]],
        ["keep extra words", "cut the tail away"], [1, 6],
        [
            text("Delete extra and its following space on line 1.", "The cursor is on extra. Press dw.", "keep words", "cut the tail away"),
            text("Delete everything after cut and its space on line 2.", "Type j0w to reach the t in the, then d$. Keep the space after cut.", "keep words", "cut "),
        ],
    ),
    lesson(
        "undo-redo", 2, "Try, undo, redo", 2,
        "Experiment freely. u undoes your last edit. Ctrl + r brings that edit back. Each edit here is a separate step.",
        [["dd", "delete a line"], ["u", "undo"], ["Ctrl + r", "redo"]],
        ["keep", "temporary", "finish"], [2, 1],
        [
            text("Delete the temporary line.", "Press dd.", "keep", "finish"),
            text("Undo the deletion to bring temporary back.", "Press u.", "keep", "temporary", "finish"),
            text("Redo the deletion.", "Hold Ctrl and press r.", "keep", "finish"),
        ],
    ),
    lesson(
        "yank-paste", 2, "Copy without a mouse", 2,
        "Vim calls copying yanking. yy copies the current line. p puts that copy below you; P puts it above.",
        [["yy", "copy current line"], ["p", "paste below"], ["P", "paste above"]],
        ["one good habit", "another good habit"], [1, 1],
        [text("Duplicate one good habit directly below itself.", "Press yy, then p.", "one good habit", "one good habit", "another good habit")],
    ),
    lesson(
        "visual", 3, "Select with intention", 2,
        "v starts a character selection. Move to grow it, then c changes the selected text and enters Insert mode.",
        [["v", "select characters"], ["e", "select to word end"], ["c", "change selection"]],
        ["Make bad choices."], [1, 6],
        [text("Select bad and change it to good.", "Type ve to select bad, press c, type good, then Esc.", "Make good choices.")],
    ),
    lesson(
        "visual-lines", 3, "Select entire lines", 2,
        "Capital V selects whole lines. Use j and k to extend the selection, then apply an action such as d or y.",
        [["V", "select whole lines"], ["j", "extend selection down"], ["d", "delete selection"]],
        ["keep me", "remove me", "remove me too", "keep me as well"], [2, 1],
        [text("Select and delete both lines beginning with remove.", "Type Vjd.", "keep me", "keep me as well")],
    ),
    lesson(
        "inner-word", 3, "Change an inner word", 2,
        "Text objects describe a piece of text. ciw means change inside word. It works from anywhere inside that word.",
        [["ciw", "change inside word"], ["diw", "delete inside word"], ["yiw", "copy inside word"]],
        ["Build tiny habits."], [1, 9],
        [text("Change tiny to small without disturbing the spaces.", "Type ciw, type small, then Esc.", "Build small habits.")],
    ),
    lesson(
        "inside-quotes", 3, "Inside the quotes", 2,
        "Text objects understand boundaries. ci\" replaces the contents of double quotes while keeping both quote characters.",
        [["ci\"", "change inside quotes"], ["di\"", "delete inside quotes"], ["yi\"", "copy inside quotes"]],
        ['message = "old words"'], [1, 13],
        [text("Replace old words with calm and clear. Keep the quotes.", 'Type ci", type calm and clear, then Esc.', 'message = "calm and clear"')],
    ),
    lesson(
        "counts", 4, "Make a command count", 1,
        "A number repeats an action or motion. 3dd deletes three lines; 3w moves three words. Let Vim do the repetition.",
        [["3dd", "delete three lines"], ["3w", "move three words"], ["5j", "move five lines"]],
        ["keep", "remove one", "remove two", "remove three", "keep too"], [2, 1],
        [text("Delete the three remove lines in one command.", "Type 3dd.", "keep", "keep too")],
    ),
    lesson(
        "dot-repeat", 4, "Do that again", 2,
        "The dot command repeats your last text change. Make one edit, move to another place, and press . to reuse it.",
        [["ciw", "change a word"], [".", "repeat last change"]],
        ["red blue", "red green", "red gold"], [1, 2],
        [
            text("Change red to amber on line 1.", "Type ciw, type amber, then Esc.", "amber blue", "red green", "red gold"),
            text("Repeat the same change on red on line 2.", "Type j0 to reach red, then press .", "amber blue", "amber green", "red gold"),
            text("Repeat once more on red on line 3.", "Type j0 and press . again.", "amber blue", "amber green", "amber gold"),
        ],
    ),
    lesson(
        "substitute", 4, "Replace across a file", 2,
        "A colon opens the command line. % means every line; the g flag replaces every match on each line.",
        [[":%s/old/new/g", "replace all occurrences"], ["Enter", "run the command"]],
        ["tea is good", "a cup of tea", "tea, tea, tea"], [1, 1],
        [text("Replace every tea with vim, including all three on line 3.", "Type :%s/tea/vim/g and press Enter.", "vim is good", "a cup of vim", "vim, vim, vim")],
    ),
    lesson(
        "save", 5, "Save your work", 2,
        "Your practice buffer is a temporary file. :w writes it to disk. In your own Vim session, :wq saves and exits; :q! discards edits.",
        [["ciw", "change inside word"], [":w ↵", "write the file"], ["F2", "return to the course"]],
        ["status: ready"], [1, 9],
        [
            text("Change ready to done and return to Normal mode.", "Type ciw, type done, then Esc.", "status: done"),
            {"kind": "write", "prompt": "Save this practice file with :w.", "hint": "Type :w and press Enter. This only writes your temporary practice file.", "target": ["status: done"]},
        ],
    ),
    lesson(
        "final-practice", 5, "Your first small edit", 4,
        "Bring the pieces together. Edit this small note one goal at a time. Use any commands you like; hints are here if you need them.",
        [["i / A", "insert text"], ["dd", "delete a line"], ["cc", "change a whole line"], ['ci"', "change inside quotes"]],
        ["# practice", "", "- learn slowly", "- skip practice", "- learn slowly", "", 'message = "maybe later"'], [1, 3],
        [
            text("Change the heading to # daily practice.", "The cursor is on p. Press i, type daily and a space, then Esc.", "# daily practice", "", "- learn slowly", "- skip practice", "- learn slowly", "", 'message = "maybe later"'),
            text("Delete the duplicate - learn slowly on line 5.", "Type 5Gdd.", "# daily practice", "", "- learn slowly", "- skip practice", "", 'message = "maybe later"'),
            text("Change - skip practice to - practice daily.", "Type 4Gcc, type - practice daily, then Esc.", "# daily practice", "", "- learn slowly", "- practice daily", "", 'message = "maybe later"'),
            text("Change the quoted message to start today.", 'Type Gf"l to move inside the quotes, then ci", type start today, and Esc.', "# daily practice", "", "- learn slowly", "- practice daily", "", 'message = "start today"'),
        ],
    ),
]


SANDBOX = {
    "id": "sandbox",
    "title": "Free practice",
    "intro": "An open page to build muscle memory. Try anything. F5 starts fresh; F2 returns to the course. This file disappears when Vim Lab exits.",
    "keys": [
        ["h j k l", "move"], ["w b e", "travel by word"], ["i a o", "enter Insert mode"],
        ["Esc", "return to Normal mode"], ["dd / yy / p", "delete, copy, paste"],
        ["u / Ctrl + r", "undo / redo"], ["v / V", "select text / lines"],
        ["ciw", "change inside word"], ['ci"', "change inside quotes"],
        [".", "repeat last change"], ["/word", "search"], [":w", "save scratch file"],
    ],
    "lines": [
        "# a little practice", "", "Take small steps.", "Keep your hands on the home row.",
        "Make a change. Undo it. Try again.", "", 'message = "you have time"',
        "", "- move with h j k l", "- change a word with ciw", "- duplicate a line with yyp", "- find something with /",
    ],
    "cursor": [3, 1],
    "goals": [],
}
