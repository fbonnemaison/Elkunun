// © 2026 App-Zilla. Licencia MIT.

/// Montículo binario mínimo sencillo.
struct PriorityQueue<Element> {
    private var heap: [Element] = []
    private let areInIncreasingOrder: (Element, Element) -> Bool

    init(by areInIncreasingOrder: @escaping (Element, Element) -> Bool) {
        self.areInIncreasingOrder = areInIncreasingOrder
    }

    var isEmpty: Bool { heap.isEmpty }
    var count: Int { heap.count }

    mutating func push(_ element: Element) {
        heap.append(element)
        var child = heap.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard areInIncreasingOrder(heap[child], heap[parent]) else { break }
            heap.swapAt(child, parent)
            child = parent
        }
    }

    mutating func pop() -> Element? {
        guard !heap.isEmpty else { return nil }
        heap.swapAt(0, heap.count - 1)
        let top = heap.removeLast()
        var parent = 0
        while true {
            let left = 2 * parent + 1
            let right = left + 1
            var best = parent
            if left < heap.count, areInIncreasingOrder(heap[left], heap[best]) { best = left }
            if right < heap.count, areInIncreasingOrder(heap[right], heap[best]) { best = right }
            if best == parent { break }
            heap.swapAt(parent, best)
            parent = best
        }
        return top
    }
}
