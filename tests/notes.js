/* eslint-env mocha */
// These are Chimp globals */
/* globals browser assert */

const countNotes = () => {
  browser.waitForVisible(".note-todo", 5000);
  const elements = browser.elements(".note-todo");
  return elements.value.length;
};

describe("note ui", () => {
  beforeEach(() => {
    browser.url("http://localhost:3100");
  });

  xit("can create a note", () => {
    const initialCount = countNotes();

    browser.click(".js-new-note");

    assert.equal(countNotes(), initialCount + 1);
  });
});
